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

    def update_from_json(json, extra_values = {}, apply_linked_records = true)

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

      self.update(self.class.prepare_for_db(json.class, updated))

      self[:user_mtime] = Time.now
      self[:last_modified_by] = RequestContext.get(:current_username)

      obj = self.save

      if apply_linked_records
        self.class.apply_linked_database_records(self, json)
      end

      self.class.fire_update(json, obj)

      obj
    end


    # Delete the current record using Sequel's delete method, but clean up
    # dependencies first.
    def delete
      (self.class.linked_records[self.class] or []).each do |linked_record|
        self.class.remove_existing_linked_records(self, linked_record)
      end

      self.class.prepare_for_deletion(self.class.where(:id => self.id))

      super

      uri = self.class.my_jsonmodel(true) && self.uri

      if uri
        Tombstone.create(:uri => uri)
        RealtimeIndexing.record_delete(uri)
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

        self.apply_linked_database_records(obj, json, true)

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
          json["created_by"] = sequel_obj[:created_by]
          json["last_modified_by"] = sequel_obj[:last_modified_by]
          json["create_time"] = sequel_obj[:create_time].getutc.iso8601
          json["system_mtime"] = sequel_obj[:system_mtime].getutc.iso8601
          json["user_mtime"] = sequel_obj[:user_mtime].getutc.iso8601

          hash = json.to_hash
          uri = sequel_obj.uri
          DB.after_commit do
            RealtimeIndexing.record_update(hash, uri)
          end
        end
      end


      @@linked_records = {}

      def linked_records
        @@linked_records
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
      #                     :corresponding_to_association  => :term,
      #                     :always_resolve => true)
      #
      # Causes an incoming JSONModel(:subject) to have each of the objects in its
      # "terms" array to be coerced into a Sequel model (based on the :terms
      # association) and stored in the database.  The provided list of terms are
      # associated with the subject as it is stored, and these replace any
      # previous terms.
      #
      # The definition also causes Subject.to_jsonmodel(obj) to
      # automatically pull back the list of terms associated with the object and
      # include them in the response.  Here, the :always_resolve parameter
      # indicates that we want the actual JSON objects to be included in the
      # response, not just their URI references.

      def def_nested_record(opts)
        opts[:association] = self.association_reflection(opts[:corresponding_to_association])
        opts[:jsonmodel] = opts[:contains_records_of_type]
        opts[:json_property] = opts[:the_property]

        opts[:is_array] = true if !opts.has_key?(:is_array)

        linked_records[self] ||= []
        linked_records[self] << opts
      end


      # Several JSONModels consist of logical subrecords that are stored as
      # separate models in the database (in separate tables).
      #
      # When we get a JSON blob for a record with subrecords, we want to create a
      # database record for each subrecords (or, if a URI referencing an existing
      # subrecord was given, use the existing object), then associate those
      # subrecords with the main record.
      #
      # If the :foreign_key option is given, any created subrecords will have
      # their column by that name set to the ID of the referring primary object.
      #
      # If the :delete_when_unassociating option is given, associated subrecords
      # being replaced will be fully deleted from the database.  This only makes
      # sense for a one-to-one or one-to-many relationship, where we want to
      # delete the object once it becomes unreferenced.
      #
      def apply_linked_database_records(obj, json, new_record = false)
        (linked_records[self] or []).each do |linked_record|

          # Remove the existing linked records
          remove_existing_linked_records(obj, linked_record) if !new_record

          # Read the subrecords from our JSON blob and fetch or create
          # the corresponding subrecord from the database.
          model = Kernel.const_get(linked_record[:association][:class_name])

          if linked_record[:association][:type] === :one_to_one
            add_record_method = linked_record[:association][:name].to_s
          elsif linked_record[:association][:type] === :many_to_one
            add_record_method = "#{linked_record[:association][:name].to_s.singularize}="
          else
            add_record_method = "add_#{linked_record[:association][:name].to_s.singularize}"
          end

          records = json[linked_record[:json_property]]

          is_array = true
          if linked_record[:association][:type] === :one_to_one || linked_record[:is_array] === false
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
                db_record = model[JSONModel(linked_record[:jsonmodel]).id_for(json_or_uri)]
                updated_records << json_or_uri
              else
                # Create a database record for the JSON blob and return its ID
                subrecord_json = JSONModel(linked_record[:jsonmodel]).from_hash(json_or_uri, true, true)

                # The value of subrecord_json can be mutated by the various
                # transformations performed by the model layer.  Make sure we
                # keep the modified version of the JSON here.
                updated_records << subrecord_json

                if model.respond_to? :ensure_exists
                  # Give our classes an opportunity to provide their own logic here
                  db_record = model.ensure_exists(subrecord_json, obj)
                else
                  extra_opts = {}

                  if linked_record[:association][:key]
                    extra_opts[linked_record[:association][:key]] = obj.id

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
                obj.mark_as_system_modified
              end

              obj.send(add_record_method, db_record) if (db_record && needs_linking)
            rescue Sequel::ValidationFailed => e
              # Modify the exception keys by prefixing each with the path up until this point.
              e.instance_eval do
                if @errors
                  prefix = linked_record[:json_property]
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

          json[linked_record[:json_property]] = is_array ? updated_records : updated_records[0]
        end
      end


      def remove_existing_linked_records(obj, record)
        model = Kernel.const_get(record[:association][:class_name])

        # now remove this record from the object
        if [:one_to_one, :one_to_many].include?(record[:association][:type])

          # remove all sub records from the object first to avoid an integrity constraints
          (linked_records[model] or []).each do |linked_record|
            (obj.send(record[:association][:name]) || []).each do |sub_obj|
              remove_existing_linked_records(sub_obj, linked_record)
            end
          end

          # Delete any relationships involving the objects from the other table (since we're about to delete them)
          dataset = obj.send("#{record[:association][:name]}_dataset")
          model.prepare_for_deletion(dataset)

          # Delete the objects from the other table
          dataset.delete
        elsif record[:association][:type] === :many_to_many
          # Just remove the links
          obj.send("remove_all_#{record[:association][:name]}".intern)
        elsif record[:association][:type] === :many_to_one
          # Just remove the link
          obj.send("#{record[:association][:name].intern}=", nil)
        end
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

        # If there are linked records for this class, grab their URI references too
        (linked_records[self] or []).each do |linked_record|
          model = Kernel.const_get(linked_record[:association][:class_name])

          records = Array(obj.send(linked_record[:association][:name])).map {|linked_obj|
            if linked_record[:always_resolve]
              model.to_jsonmodel(linked_obj).to_hash(:trusted)
            else
              JSONModel(linked_record[:jsonmodel]).uri_for(linked_obj.id, :repo_id => active_repository) or
                raise "Couldn't produce a URI for record type: #{linked_record[:type]}."
            end
          }

          is_array = linked_record[:is_array] && ![:many_to_one, :one_to_one].include?(linked_record[:association][:type])

          json[linked_record[:json_property]] = (is_array ? records : records[0])
        end

        json["created_by"] = obj[:created_by] if obj[:created_by]
        json["last_modified_by"] = obj[:last_modified_by] if obj[:last_modified_by]
        json["system_mtime"] = obj[:system_mtime].getutc.iso8601 if obj[:system_mtime]
        json["user_mtime"] = obj[:user_mtime].getutc.iso8601 if obj[:user_mtime]
        json["create_time"] = obj[:create_time].getutc.iso8601 if obj[:create_time]

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

    end
  end


  # Hooks for firing behaviour on Sequel::Model events
  module SequelHooks

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

        (linked_records[self] or []).each do |linked_record|
          # Linked records will be processed separately by
          # apply_linked_database_records.  Don't include them when saving to the
          # database.
          hash.delete(linked_record[:json_property].to_s)
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
