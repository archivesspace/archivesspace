require 'csv'
require_relative 'aspace_json_to_managed_container_mapper'


class ContainerManagementConversion
    

  def self.already_run?
      DB.open do |db|
        return  !db[:system_event].where( :title => "CONTAINER_MANAGEMENT_UPGRADE_COMPLETED" ).empty? 
      end
  end

  # For performance reasons, we're going to feed the ASpace -> Container
  # Management mapper something that behaves like a JSONModel but isn't fully
  # realized.
  #
  # We don't want to have to pull every field of every record back just to
  # update their instances.
  #
  # So, this implements just enough of our JSONModels to keep the mapper happy.
  MIGRATION_MODELS = {}
  
  CONVERSION_REPORT_HEADERS  = %w{ error message url uri parent resource instances instance_ids preconversion_locations postconversion_locations conversion_context }

  def ContainerMigrationModel(model_type)

    MIGRATION_MODELS[model_type] ||= Class.new(JSONModel::JSONModel(model_type)) do

      include JSONModel

      def initialize(record, job = nil, error_log = nil)
        @acting_as = record.class
        @fields = {}
        @job = job
        @error_log = error_log 

        load_relevant_fields(record)
      end

      def is_a?(clz)
        @acting_as.my_jsonmodel == clz
      end

      def [](key)
        @fields.fetch(key.to_s)
      end

      def create_containers(top_containers_in_this_tree)
        # If our incoming instance records already have their subcontainers created, we won't create them again.
        instances_with_subcontainers = self['instance_ids'].zip(self['instances']).map {|instance_id, instance|
          if instance['sub_container']
            instance_id
          end
        }.compact

        begin
          MigrationMapper.new(self, false, top_containers_in_this_tree).call
        rescue JSONModel::ValidationException => e
        
          DB.open do |db|
            db[:system_event].insert(:title => "CONTAINER_MANAGEMENT_UPGRADE_WARNING",
                                   :message => e.message[0..250], 
                                   :time => Time.now)
          end
          
          
          
         
          row = CSV::Row.new([],[],false)
       
          row << { "error" => e.class }
          e.errors.each do |ek, ev|
            row << { "message" => "#{ek} -- #{ev.join(',') }" } 
          end

          if @fields.has_key?("uri")
            row << { "url" => "#{AppConfig[:frontend_proxy_url]}/resolve/readonly?uri=#{@fields["uri"]}" }
          end
        

          @fields.each do |k, v|
            case v
            when String
              row << {k => v}
            when Array
              row << {k => v.join(" ; ")}
            when Hash
              row << {k => v.values.join(" ; ")}
            else # i dunno?
              row << {k => v}
            end
          end

          top_container_locations = e.object_context[:top_container_locations] || []
          aspace_locations = e.object_context[:aspace_locations] || [] 
          

          row << { "postconversion_locations" => top_container_locations.join('; '), 
                   "preconversion_locations" => aspace_locations.join("; "),
                   "conversion_context" => e.object_context.inspect } 

          @error_log << row.fields(*ContainerManagementConversion::CONVERSION_REPORT_HEADERS)
          
          Log.error("A ValidationException was raised while the container migration took place.  Please investigate this, as it likely indicates data issues that will need to be resolved by hand")
          Log.exception(e)
          
          @job.write_output(Log.backlog) if @job
          
        
        end
        

        self['instance_ids'].zip(self['instances']).map {|instance_id, instance|
          # Create a new subcontainer that links everything up
          if instance['sub_container']

            # This subcontainer was added by the mapping process.  Create it.
            if !instances_with_subcontainers.include?(instance_id)
              SubContainer.create_from_json(JSONModel(:sub_container).from_hash(instance['sub_container']), :instance_id => instance_id)
            end

            # Extract the top container we linked to and return it if we haven't seen it before
            top_container_id = JSONModel(:top_container).id_for(instance['sub_container']['top_container']['ref'])

            if !top_containers_in_this_tree.has_key?(top_container_id)
              TopContainer[top_container_id]
            else
              nil
            end
          end
        }.compact
          

      end


      private

      def load_relevant_fields(record)
        @fields['uri'] = record.uri

        # Set the fields that are used by the mapper to walk the tree.
        if record.is_a?(ArchivalObject)
          if record.parent_id
            @fields['parent'] = {'ref' => ArchivalObject.uri_for(:archival_object, record.parent_id)}
          end

          if record.root_record_id
            @fields['resource'] = {'ref' => Resource.uri_for(:resource, record.root_record_id)}
          end
        end

        # Find the existing instances and their IDs and load them in as well.
        instance_join_column = record.class.association_reflection(:instance)[:key]

        @fields['instances'] = []
        @fields['instance_ids'] = []
        Instance.filter(instance_join_column => record.id).each do |instance|
          @fields['instances'] << Instance.to_jsonmodel(instance).to_hash(:trusted)
          @fields['instance_ids'] << instance.id
        end
      end
    end
  end


  # An extension of the standard mapper which gets handed hashes of all top
  # containers used in the current resource and series.  Uses those to avoid
  # expensive SQL queries to search back up the tree.
  class MigrationMapper < AspaceJsonToManagedContainerMapper


    def initialize(json, new_record, resource_top_containers)
      super(json, new_record)
      @resource_top_containers = resource_top_containers
    end


    # this is used for searching AOs. Important to note this duck patch is
    # used only in the container mgmn conversion...
    def try_matching_indicator_within_collection(container)
      
      indicator = container['indicator_1']
      type = container["type_1"]
      
      @resource_top_containers.values.find {|top_container| top_container.indicator == indicator && top_container.type == type}
    end

    def get_or_create_top_container(instance)
      extent = create_extents_from_container_extents(instance)
      fields = @json.instance_variable_get("@fields".intern) #yuck 
      uri = fields["uri"] || nil 

      if extent && uri && uri.length > 0 
        opts = case @json
              when JSONModel(:accession)
                { :accession_id => @json.class.id_for(uri) }
              when JSONModel(:resource)
                { :resource_id =>  @json.class.id_for(uri) }
              when JSONModel(:archival_object)
                { :archival_object_id  => @json.class.id_for(uri) }
              end

        Log.info("Creating a new extent record with values #{extent.inspect} #{opts.inspect}")
        Extent.create_from_json(extent, opts)
      end
      super(instance) 
    
    end

  end


  MAX_RECORDS_PER_TRANSACTION = 10
  def convert
    
    if AppConfig[:plugins].include?("container_management") 
      Log.info("*" * 100 )
      Log.info("*\t\t You have the container_managment set in your AppConfig[:plugins] setting. We will not run the container conversion process.") 
      Log.info("*" * 100 )
      return    
    end
    
    records_migrated = 0

    Repository.all.each do |repo|
      
      RequestContext.open(:repo_id => repo.id,
                          :is_high_priority => false,
                          :current_username => "admin") do

        
        begin 
          job_json = JSONModel::JSONModel(:job).from_hash({
                                  :job => JSONModel::JSONModel(:container_conversion_job).from_hash({ :format => 'csv' }), 
                                  :job_type => 'container_conversion_job',
                                 })


          user = User.find(:username => 'admin') 
          @job = Job.create_from_json(job_json,
                             :repo_id => repo.id, :user => user
                                     ) 
         
          h = CSV::Row.new(ContainerManagementConversion::CONVERSION_REPORT_HEADERS,[],true)
          @error_log = CSV::Table.new([h])

          # Migrate accession records
          Accession.filter(:repo_id => repo.id).each do |accession|
            Log.info("Working on Accession #{accession.id} (records migrated: #{records_migrated})")
            @job.write_output(Log.backlog) if @job
            records_migrated += 1
            ContainerMigrationModel(:accession).new(accession, @job, @error_log).create_containers({})
          end

          # Then resources and containers
          Resource.filter(:repo_id => repo.id).each do |resource|
            top_containers_in_this_tree = {}

            records_migrated += 1
            ContainerMigrationModel(:resource).new(resource, @job, @error_log).create_containers(top_containers_in_this_tree).each do |top_container|
              top_containers_in_this_tree[top_container.id] = top_container
            end

            ao_roots = resource.tree['children']

            ao_roots.each do |ao_root|
              work_queue = [ao_root]

              while !work_queue.empty?

                nodes_for_transaction = []
                while !work_queue.empty?
                  nodes_for_transaction << work_queue.shift
                  break if nodes_for_transaction.length == MAX_RECORDS_PER_TRANSACTION
                end

                Log.info("Running #{nodes_for_transaction.length} for the next transaction")
                @job.write_output(Log.backlog) if @job

                DB.open do
                  nodes_for_transaction.each do |node|
                    work_queue.concat(node['children'])

                    record = ArchivalObject[node['id']]

                    Log.info("Working on ArchivalObject #{record.id} (records migrated: #{records_migrated})")
                    @job.write_output(Log.backlog) if @job

                    migration_record = ContainerMigrationModel(:archival_object).new(record, @job, @error_log)

                    migration_record.create_containers(top_containers_in_this_tree).each do |top_container|
                      top_containers_in_this_tree[top_container.id] = top_container
                    end

                    records_migrated += 1
                  end
                end
              end
            end
        
          end # Resource.each
        
        ensure
        
          if @job
            file = ASUtils.tempfile("container_conversion_")
            file.write(@error_log.to_csv)
            file.rewind 
            @job.add_file(file) 
            
            @job.write_output("Finished container conversion for repository #{repo.id}")
            @job.finish!(:completed)
          end 
          
        end
      end
    end



  end




  def run
  
    # just in case....
    if self.class.already_run?
      Log.info("*" * 100 )
      Log.info("*\t\t How did you get here? The container management conversion process has already run, or at least there's log of it in the system_event table.") 
      Log.info("*" * 100 )
      return    
    end
    
    DB.open do |db|
      db[:system_event].insert(:title => "CONTAINER_MANAGEMENT_UPGRADE_STARTED",
                                 :time => Time.now)
    end

    convert
    
    DB.open do |db|
      db[:system_event].insert(:title => "CONTAINER_MANAGEMENT_UPGRADE_COMPLETED",
                                 :time => Time.now)
    end



  end
end
