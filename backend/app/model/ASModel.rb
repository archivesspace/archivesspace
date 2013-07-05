require_relative '../lib/realtime_indexing'
require 'date'

module ASModel
  include JSONModel

  @@all_models = []

  def self.all_models
    @@all_models
  end

  def self.included(base)
    base.instance_eval do
      plugin :optimistic_locking
      plugin :validation_helpers
    end

    base.extend(JSONModel)

    base.include(CRUD)
    base.include(RepositoryTransfers)
    base.include(DatabaseMapping)
    base.include(SequelHooks)
    base.include(ModelScoping)

    @@all_models << base
  end


  # Code for converting JSONModels into DB records and back again.
  module CRUD

    def self.included(base)
      base.extend(ClassMethods)
      base.extend(JSONModel)
    end

    Sequel.extension :inflector


    def self.set_audit_fields(json, obj)
      ['created_by', 'last_modified_by', 'system_mtime', 'user_mtime', 'create_time'].each do |field|
        json[field] = obj[field.intern] if obj[field.intern]
      end
    end

    def validate
      # Check uniqueness constraints
      self.class.repo_unique_constraints.each do |constraint|
        validates_unique([:repo_id, constraint[:property]],
                         :message => constraint[:message])
        map_validation_to_json_property([:repo_id, constraint[:property]],
                                         constraint[:json_property])
      end

      super
    end


    # Several JSONModels consist of logical subrecords that are stored as
    # separate models in the database (in separate tables).
    #
    # When we get a JSON blob for a record with subrecords, we want to create a
    # database record for each subrecords (or, if a URI referencing an existing
    # subrecord was given, use the existing object), then associate those
    # subrecords with the main record.
    def apply_nested_records(json, new_record = false)

      self.remove_nested_records if !new_record

      self.class.nested_records.each do |nested_record|
        # Read the subrecords from our JSON blob and fetch or create
        # the corresponding subrecord from the database.
        model = Kernel.const_get(nested_record[:association][:class_name])

        if nested_record[:association][:type] === :one_to_one
          add_record_method = nested_record[:association][:name].to_s
        elsif nested_record[:association][:type] === :many_to_one
          add_record_method = "#{nested_record[:association][:name].to_s.singularize}="
        else
          add_record_method = "add_#{nested_record[:association][:name].to_s.singularize}"
        end

        records = json[nested_record[:json_property]]

        is_array = true
        if nested_record[:association][:type] === :one_to_one || nested_record[:is_array] === false
          is_array = false
          records = [records]
        end

        updated_records = []
        (records or []).each_with_index do |json_or_uri, i|
          next if json_or_uri.nil?

          db_record = nil

          begin
            needs_linking = true

            if json_or_uri.kind_of? String
              # A URI.  Just grab its database ID and look it up.
                      db_record = model[JSONModel(nested_record[:jsonmodel]).id_for(json_or_uri)]
              updated_records << json_or_uri
            else
              # Create a database record for the JSON blob and return its ID
              subrecord_json = JSONModel(nested_record[:jsonmodel]).from_hash(json_or_uri, true, true)

              # The value of subrecord_json can be mutated by the various
              # transformations performed by the model layer.  Make sure we
              # keep the modified version of the JSON here.
              updated_records << subrecord_json

              if model.respond_to? :ensure_exists
                # Give our classes an opportunity to provide their own logic here
                db_record = model.ensure_exists(subrecord_json, self)
              else
                extra_opts = {}

                if nested_record[:association][:key]
                  extra_opts[nested_record[:association][:key]] = self.id

                  # We'll skip the call to the .add method because this step
                  # will have already linked the nested record to this one.
                  needs_linking = false
                end

                db_record = model.create_from_json(subrecord_json, extra_opts)
              end
            end

            if db_record.system_modified?
              # If the subrecord got changed by the system, mark ourselves as
              # modified too.
              self.mark_as_system_modified
            end

            self.send(add_record_method, db_record) if (db_record && needs_linking)
          rescue Sequel::ValidationFailed => e
            # Modify the exception keys by prefixing each with the path up until this point.
            e.instance_eval do
              if @errors
                prefix = nested_record[:json_property]
                prefix = "#{prefix}/#{i}" if is_array

                new_errors = {}
                @errors.each do |k, v|
                  new_errors["#{prefix}/#{k}"] = v
                end

                @errors = new_errors
              end
            end

            raise e
          end
        end

        json[nested_record[:json_property]] = is_array ? updated_records : updated_records[0]
      end
    end


    def remove_nested_records
      self.class.nested_records.each do |nested_record_defn|
        if [:one_to_one, :one_to_many].include?(nested_record_defn[:association][:type])
          # If the current record "owns" its nested record, delete the nested record.
          model = Kernel.const_get(nested_record_defn[:association][:class_name])

          # Tell the nested record to clear its own nested records
          Array(self.send(nested_record_defn[:association][:name])).each do |nested_record|
            nested_record.remove_nested_records
          end

          # Now delete all nested objects
          dataset = self.send("#{nested_record_defn[:association][:name]}_dataset")
          model.prepare_for_deletion(dataset)
          dataset.delete
        elsif nested_record_defn[:association][:type] === :many_to_many
          # Just remove the links
          self.send("remove_all_#{nested_record_defn[:association][:name]}".intern)
        elsif nested_record_defn[:association][:type] === :many_to_one
          # Just remove the link
          self.send("#{nested_record_defn[:association][:name].intern}=", nil)
        end
      end
    end



    def update_from_json(json, extra_values = {}, apply_nested_records = true)

      if self.values.has_key?(:suppressed)
        if self[:suppressed] == 1
          raise ReadOnlyException.new("Can't update an object that has been suppressed")
        end

        # No funny business.  If you want to set this you need to do it via the
        # dedicated controller.
        json["suppressed"] = false
      end


      schema_defined_properties = json.class.schema["properties"].map{|prop, defn|
        prop if !defn['readonly']
      }.compact

      # Start by assuming all existing properties were nil, then overlay the
      # updates plus any extra attributes.
      #
      # This has the effect of unsetting (or setting to NULL) any properties that
      # were removed by this update.
      updated = Hash[schema_defined_properties.map {|property| [property, nil]}].
        merge(json.to_hash).
        merge(ASUtils.keys_as_strings(extra_values))

      if updated.has_key?('lock_version') && !updated['lock_version']
        raise ConflictException.new("You must provide a lock_version in your request")
      end

      self.class.strict_param_setting = false

      self.update(self.class.prepare_for_db(json.class, updated).
                  merge(:user_mtime => Time.now,
                        :last_modified_by => RequestContext.get(:current_username)))

      if apply_nested_records
        self.apply_nested_records(json)
      end

      self.class.fire_update(json, self)

      self
    end


    # Delete the current record using Sequel's delete method, but clean up
    # dependencies first.
    def delete
      self.remove_nested_records
      self.class.prepare_for_deletion(self.class.where(:id => self.id))

      super

      uri = self.class.my_jsonmodel(true) && self.uri

      if uri
        Tombstone.create(:uri => uri)
        DB.after_commit do
          RealtimeIndexing.record_delete(uri)
        end
      end
    end


    # Mixins will hook in here to add their own publish actions.
    def publish!
      self.publish = 1
      self.save
    end


    # When reporting a Sequel validation error against the set of 'columns',
    # report it against the JSONModel 'property' instead.
    #
    # For example, an identifier that must be unique to a repository might have a
    # constraint against the columns [:repository, :identifier], but when we
    # report this to the client we just want to tell them that the value for
    # 'identifier' was incorrect.
    def map_validation_to_json_property(columns, property)
      errors = self.errors.clone

      self.errors.clear

      errors.each do |error, msg|
        if error == columns
          self.errors[property] = msg
        else
          self.errors[error] = msg
        end
      end
    end


    # True if this record has been modified by some mechanism other than a request
    # from the client.  Used to send a status back to the client to let them know
    # that they'll need to fetch the latest representation.
    #
    # For example, this flag is used when the user's data is combined with a
    # system-generated ID to create a record.  The user needs to refetch to ensure
    # that their local copy of the record includes the system-generated data too.
    def system_modified?
      @system_modified
    end


    def mark_as_system_modified
      @system_modified = true
    end


    module ClassMethods

      # Create a new record instance from the JSONModel 'json'.  Also creates any
      # nested record instances that it contains.
      def create_from_json(json, extra_values = {})
        self.strict_param_setting = false
        values = ASUtils.keys_as_strings(extra_values)

        if model_scope == :repository && !values.has_key?("repo_id")
          values["repo_id"] = active_repository
        end

        values['created_by'] = RequestContext.get(:current_username)

        obj = self.create(prepare_for_db(json.class,
                                         json.to_hash.merge(values)))

        obj.apply_nested_records(json, true)

        fire_update(json, obj)

        obj
      end


      def high_priority?
        RequestContext.get(:is_high_priority)
      end


      # (Potentially) notify the real-time indexer that an update is available.
      def fire_update(json, sequel_obj)
        if high_priority?
          sequel_obj.refresh

          # Manually set any DB hooked values
          CRUD.set_audit_fields(json, sequel_obj)

          hash = json.to_hash
          uri = sequel_obj.uri
          DB.after_commit do
            RealtimeIndexing.record_update(hash, uri)
          end
        end
      end


      def nested_records
        @nested_records ||= []
      end


      # Match a JSONModel object to an existing database association.
      #
      # This linkage manages records that contain subrecords:
      #
      #  - When storing a JSON blob in the database, the linkage indicates which
      #    parts of the JSON should be plucked out and stored as separate database
      #    records (with the appropriate associations)
      #
      #  - When requesting a record in JSON format, the linkage indicates which
      #    associated database records should be pulled back and included in the
      #    JSON returned.
      #
      # For example, this definition from subject.rb:
      #
      #   def_nested_record(:the_property => :terms,
      #                     :contains_records_of_type => :term,
      #                     :corresponding_to_association  => :term)
      #
      # Causes an incoming JSONModel(:subject) to have each of the objects in its
      # "terms" array to be coerced into a Sequel model (based on the :terms
      # association) and stored in the database.  The provided list of terms are
      # associated with the subject as it is stored, and these replace any
      # previous terms.
      #
      # The definition also causes Subject.to_jsonmodel(obj) to
      # automatically pull back the list of terms associated with the object and
      # include them in the response.

      def def_nested_record(opts)
        opts[:association] = self.association_reflection(opts[:corresponding_to_association])
        opts[:jsonmodel] = opts[:contains_records_of_type]
        opts[:json_property] = opts[:the_property]

        opts[:is_array] = true if !opts.has_key?(:is_array)

        nested_records << opts
      end


      def get_or_die(id)
        obj = if self.model_scope == :repository
                self.this_repo[:id => id]
              else
                self[id]
              end

        obj or raise NotFoundException.new("#{self} not found")
      end


      def corresponds_to(jsonmodel)
        @jsonmodel = jsonmodel

        include(DynamicEnums)

        enums = []
        @jsonmodel.schema['properties'].each do |prop, defn|
          if defn["dynamic_enum"]
            enums << {:property => prop, :uses_enum => defn['dynamic_enum']}
          end
        end

        uses_enums(*enums)
      end


      # Does this model have a corresponding JSONModel?
      def has_jsonmodel?
        !@jsonmodel.nil?
      end


      # Return the JSONModel class that maps to this backend model
      def my_jsonmodel(ok_if_missing = false)
        @jsonmodel or (ok_if_missing ? nil : raise("No corresponding JSONModel set for model #{self.inspect}"))
      end


      def sequel_to_jsonmodel(obj, opts = {})
        json = my_jsonmodel.new(map_db_types_to_json(my_jsonmodel.schema,
                                                     obj.values.reject {|k, v| v.nil? }))

        uri = json.class.uri_for(obj.id, :repo_id => active_repository)
        json.uri = uri if uri

        if model_scope == :repository
          json['repository'] = {'ref' => JSONModel(:repository).uri_for(active_repository)}
        end

        # If there are nested records for this class, grab their URI references too
        nested_records.each do |nested_record|
          model = Kernel.const_get(nested_record[:association][:class_name])

          records = Array(obj.send(nested_record[:association][:name])).map {|linked_obj|
            model.to_jsonmodel(linked_obj).to_hash(:trusted)
          }

          is_array = nested_record[:is_array] && ![:many_to_one, :one_to_one].include?(nested_record[:association][:type])

          json[nested_record[:json_property]] = (is_array ? records : records[0])
        end

        CRUD.set_audit_fields(json, obj)

        json
      end


      def to_jsonmodel(obj, opts = {})
        if obj.is_a? Integer
          # An ID.  Get the Sequel row for it.
                  obj = get_or_die(obj)
        end

        sequel_to_jsonmodel(obj, opts)
      end


      def prepare_for_deletion(dataset)
        # Provide a hook for models to do something in response to a dataset being deleted.
        # We won't do anything here, but mixins can add to this.
      end


      def update_mtime_for_ids(ids)
        now = Time.now
        ids.each_slice(50) do |subset|
          self.dataset.filter(:id => subset).update(:system_mtime => now)
        end
      end


      def repo_unique_constraints
        Array(@repo_unique_constraints)
      end


      def repo_unique_constraint(property, constraints)
        @repo_unique_constraints ||= []
        @repo_unique_constraints << constraints.merge(:property => property)
      end

    end
  end


  # Code for moving records between repositories
  module RepositoryTransfers

    def self.included(base)
      base.extend(ClassMethods)
    end


    def transfer_to_repository(repository, transfer_group = [])

      if self.values.has_key?(:repo_id)
        old_uri = self.uri

        old_repo = Repository[self.repo_id]

        self.repo_id = repository.id
        self.system_mtime = Time.now
        save(:repo_id, :system_mtime)

        # Mark the (now changed) URI as deleted
        if old_uri
          Tombstone.create(:uri => old_uri)
          DB.after_commit do
            RealtimeIndexing.record_delete(old_uri)
          end

          # Create an event if this is the top-level record being transferred.
          if transfer_group.empty?
            RequestContext.open(:repo_id => repository.id) do
              Event.for_repository_transfer(old_repo, repository, self)
            end
          end
        end
      end

      # Tell any nested records to transfer themselves too
      self.class.nested_records.each do |nested_record_defn|
        association = nested_record_defn[:association][:name]
        Array(self.send(association)).each do |nested_record|
          nested_record.transfer_to_repository(repository)
        end
      end
    end


    module ClassMethods

      def report_incompatible_constraints(source_repository, target_repository)
        problems = {}

        repo_unique_constraints.each do |constraint|
          target_repo_values = self.filter(:repo_id => target_repository.id).
                                    select(constraint[:property])

          overlapping_in_source = self.filter(:repo_id => source_repository.id,
                                              constraint[:property] => target_repo_values).
                                       select(:id)

          if overlapping_in_source.count > 0
            overlapping_in_source.each do |obj|
              problems[obj.uri] ||= []
              problems[obj.uri] << {
                :json_property => constraint[:json_property],
                :message => constraint[:message]
              }
            end
          end
        end

        if !problems.empty?
          raise TransferConstraintError.new(problems)
        end
      end


      def transfer_all(source_repository, target_repository)
        if self.columns.include?(:repo_id)

          report_incompatible_constraints(source_repository, target_repository)


          # One delete marker per URI
          if self.has_jsonmodel?
            jsonmodel = self.my_jsonmodel
            self.filter(:repo_id => source_repository.id).select(:id).each do |row|
              Tombstone.create(:uri => jsonmodel.uri_for(row[:id], :repo_id => source_repository.id))
            end
          end

          self.filter(:repo_id => source_repository.id).
               update(:repo_id => target_repository.id,
                      :system_mtime => Time.now)
        end
      end

    end

  end


  # Hooks for firing behaviour on Sequel::Model events
  module SequelHooks

    def self.included(base)
      base.extend(BlobHack)
    end

    # We can save quite a lot of database chatter by only refreshing our
    # top-level records upon save.  Pure-nested records don't need refreshing,
    # so skip them.
    def _save_refresh
      if self.class.respond_to?(:has_jsonmodel?) && self.class.has_jsonmodel? && self.class.my_jsonmodel.schema['uri']
        _refresh(this.opts[:server] ? this : this.server(:default))
      end
    end

    def before_create
      if RequestContext.get(:current_username)
        self.created_by = self.last_modified_by = RequestContext.get(:current_username)
      end
      self.create_time = Time.now
      self.system_mtime = self.user_mtime = Time.now
      super
    end


    def before_update
      if RequestContext.get(:current_username)
        self.last_modified_by = RequestContext.get(:current_username)
      end
      self.system_mtime = Time.now
      super
    end


    def around_save
      values_to_reapply = {}

      self.class.blob_columns_to_fix.each do |column|
        if self[column]
          values_to_reapply[column] = self[column]
          self[column] = nil
        end
      end

      ret = super

      if !values_to_reapply.empty?
        ps = self.class.dataset.where(:id => self.id).prepare(:update, :update_blobs,
                                                             Hash[values_to_reapply.keys.map {|c| [c, :"$#{c}"]}])

        ps.call(Hash[values_to_reapply.map {|k, v| [k, DB.blobify(v)]}])

        self.refresh
      end

      ret
    end


    module BlobHack
      def self.extended(base)
        blob_columns = base.db_schema.select {|column, defn| defn[:type] == :blob}.keys

        base.instance_eval do
          @blob_columns_to_fix = (!blob_columns.empty? && DB.needs_blob_hack?) ? Array(blob_columns) : []
        end
      end

      def blob_columns_to_fix
        @blob_columns_to_fix
      end

    end
  end


  # Some low-level details of mapping certain Ruby types to database types.
  module DatabaseMapping

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      JSON_TO_DB_MAPPINGS = {
        'boolean' => {
          :description => "JSON booleans become DB integers",
          :json_to_db => ->(bool) { bool ? 1 : 0 },
          :db_to_json => ->(int) { int === 1 }
        },
        'date' => {
          :description => "Date strings become dates",
          :json_to_db => ->(s) { Date.parse(s) },
          :db_to_json => ->(date) { date.strftime('%Y-%m-%d') }
        }
      }


      def prepare_for_db(jsonmodel_class, hash)
        schema = jsonmodel_class.schema
        hash = hash.clone
        schema['properties'].each do |property, definition|
          mapping = JSON_TO_DB_MAPPINGS[definition['type']]
          if mapping && hash.has_key?(property)
            hash[property] = mapping[:json_to_db].call(hash[property])
          end
        end

        nested_records.each do |nested_record|
          # Nested records will be processed separately.
          hash.delete(nested_record[:json_property].to_s)
        end

        hash['json_schema_version'] = jsonmodel_class.schema_version

        hash
      end


      def map_db_types_to_json(schema, hash)
        hash = hash.clone
        schema['properties'].each do |property, definition|
          mapping = JSON_TO_DB_MAPPINGS[definition['type']]

          property = property.intern
          if mapping && hash.has_key?(property)
            hash[property] = mapping[:db_to_json].call(hash[property])
          end
        end

        hash
      end


      def shortname
        self.table_name.to_s.split("_").map {|s| s[0...3]}.join("_")
      end
    end

  end



  # Code that keeps the records of different repositories isolated and hiding suppressed records.
  module ModelScoping

    def self.included(base)
      base.extend(ClassMethods)
    end


    def uri
      # Bleh!
      self.class.uri_for(self.class.my_jsonmodel.record_type, self.id)
    end


    module ClassMethods

      def enable_suppression
        @suppressible = true
      end


      def enforce_suppression?
        RequestContext.get(:enforce_suppression)
      end


      def suppressible?
        @suppressible
      end

      def set_model_scope(value)
        if ![:repository, :global].include?(value)
          raise "Failure for #{self}: Model scope must be set as :repository or :global"
        end

        if value == :repository
          model = self
          orig_ds = self.dataset.clone

          # Provide a new '.this_repo' method on this model class that only
          # returns records that belong to the current repository.
          def_dataset_method(:this_repo) do
            filter = {:repo_id => model.active_repository}

            if model.suppressible? && model.enforce_suppression?
              filter[:suppressed] = 0
            end

            orig_ds.filter(filter)
          end


          # And another that will return records from any repository
          def_dataset_method(:any_repo) do
            if model.suppressible? && model.enforce_suppression?
              orig_ds.filter(:suppressed => 0)
            else
              orig_ds
            end
          end


          # Replace the default row_proc with one that fetches the request row,
          # but blows up if that row isn't from the currently active repository.
          orig_row_proc = self.dataset.row_proc
          self.dataset.row_proc = proc do |row|
            if row.has_key?(:repo_id) && row[:repo_id] != model.active_repository
              raise ("ASSERTION FAILED: #{row.inspect} has a repo_id of " +
                     "#{row[:repo_id]} but the active repository is #{model.active_repository}")
            end

            orig_row_proc.call(row)
          end

        end

        @model_scope = value
      end


      def model_scope(noerror = false)
        @model_scope or
          if noerror
            nil
          else
            raise "set_model_scope definition missing for model #{self}"
          end
      end


      # Like JSONModel.parse_reference, but enforce repository restrictions
      def parse_reference(uri, opts)
        ref = JSONModel.parse_reference(uri, opts)

        # If the current model is repository scoped, and the reference is a
        # repository-scoped URI, make sure they're talking about the same
        # repository.
        if ref && self.model_scope == :repository && uri.start_with?("/repositories/")
          if !uri.start_with?("/repositories/#{active_repository}/")
            raise ReferenceError.new("Invalid URI reference for this (#{active_repository}) repo: '#{uri}'")
          end
        end

        ref
      end


      def active_repository
        repo = RequestContext.get(:repo_id)

        if model_scope == :repository and repo.nil?
          raise "Missing repo_id for request!"
        end

        repo
      end


      def uri_for(jsonmodel, id, opts = {})
        JSONModel(jsonmodel).uri_for(id, opts.merge(:repo_id => self.active_repository))
      end

    end
  end

end


require_relative 'mixins/dynamic_enums'
