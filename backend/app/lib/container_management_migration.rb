class ContainerManagementMigration

  # For performance reasons, we're going to feed the ASpace -> Container
  # Management mapper something that behaves like a JSONModel but isn't fully
  # realized.
  #
  # We don't want to have to pull every field of every record back just to
  # update their instances.
  #
  # So, this implements just enough of our JSONModels to keep the mapper happy.
  MIGRATION_MODELS = {}

  def ContainerMigrationModel(model_type)

    MIGRATION_MODELS[model_type] ||= Class.new(JSONModel::JSONModel(model_type)) do

      include JSONModel

      def initialize(record)
        @acting_as = record.class
        @fields = {}

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

        MigrationMapper.new(self, false, top_containers_in_this_tree).call

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


    def try_matching_indicator_within_collection(container)
      indicator = container['indicator_1']
      @resource_top_containers.values.find {|top_container| top_container.indicator == indicator}
    end


    def ensure_harmonious_values(*)
      begin
        super
      rescue ValidationException => e
        Log.error("A ValidationException was raised while the container migration took place.  Please investigate this, as it likely indicates data issues that will need to be resolved by hand")
        Log.exception(e)
      end
    end

  end


  MAX_RECORDS_PER_TRANSACTION = 10


  def run
    records_migrated = 0

    Repository.all.each do |repo|
      RequestContext.open(:repo_id => repo.id,
                          :is_high_priority => false,
                          :current_username => "admin") do

        # Migrate accession records
        Accession.filter(:repo_id => repo.id).each do |accession|
          Log.info("Working on Accession #{accession.id} (records migrated: #{records_migrated})")
          records_migrated += 1
          ContainerMigrationModel(:accession).new(accession).create_containers({})
        end

        # Then resources and containers
        Resource.filter(:repo_id => repo.id).each do |resource|
          top_containers_in_this_tree = {}

          records_migrated += 1
          ContainerMigrationModel(:resource).new(resource).create_containers(top_containers_in_this_tree).each do |top_container|
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

              DB.open do
                nodes_for_transaction.each do |node|
                  work_queue.concat(node['children'])

                  record = ArchivalObject[node['id']]

                  Log.info("Working on ArchivalObject #{record.id} (records migrated: #{records_migrated})")

                  migration_record = ContainerMigrationModel(:archival_object).new(record)

                  migration_record.create_containers(top_containers_in_this_tree).each do |top_container|
                    top_containers_in_this_tree[top_container.id] = top_container
                  end

                  records_migrated += 1
                end
              end
            end
          end
        end
      end
    end
  end
end
