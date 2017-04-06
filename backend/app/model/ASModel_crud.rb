require_relative '../lib/nested_record_resolver'

module ASModel

  # Code for converting JSONModels into DB records and back again.
  module CRUD

    def self.included(base)
      base.extend(ClassMethods)
      base.include(JSONModel)
      base.extend(JSONModel)
    end

    Sequel.extension :inflector
    Sequel.extension(:core_extensions)

    def self.set_audit_fields(json, obj)
      ['created_by', 'last_modified_by'].each do |field|
        json[field] = obj[field.intern] if obj[field.intern]
      end

      ['system_mtime', 'user_mtime', 'create_time'].each do |field|
        val = obj[field.intern]
        next if !val

        json[field] = val.getutc.iso8601
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


    # Do whatever is necessary to eaglerly load this object from the database.
    #
    # This is designed to give mixins the options of eagerly loading an entire
    # record and its components.
    def eagerly_load!
      # Do nothing by default
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
            nested_record.delete
          end
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
      object_graph = self.object_graph

      deleted_uris = []

      successfully_deleted_models = []
      last_error = nil

      while true
        progressed = false
        object_graph.each do |model, ids_to_delete|
          next if successfully_deleted_models.include?(model)

          begin
            model.handle_delete(ids_to_delete)
            successfully_deleted_models << model
            progressed = true
          rescue Sequel::DatabaseError
            last_error = $!
            next
          end

          if model.my_jsonmodel(true)
            ids_to_delete.each do |id|
              deleted_uri = model.my_jsonmodel(true).
                                  uri_for(id, :repo_id => model.active_repository)

              if deleted_uri
                deleted_uris << deleted_uri
              end
            end
          end
        end

        break if object_graph.models.length == successfully_deleted_models.length

        unless progressed
          if last_error && DB.is_retriable_exception(last_error)
            # Give us a chance to retry after a deadlock
            raise last_error
          end

          raise ConflictException.new("Record deletion failed: #{last_error}")
        end
      end


      deleted_uris.each do |uri|
        Tombstone.create(:uri => uri)
        DB.after_commit do
          RealtimeIndexing.record_delete(uri)
        end
      end
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

        obj.refresh
        obj
      end


      def high_priority?
        RequestContext.get(:is_high_priority)
      end


      # (Potentially) notify the real-time indexer that an update is available.
      def fire_update(json, sequel_obj)
        if high_priority?
          model = self

          uri = sequel_obj.uri

          # We don't index records without URIs, so no point digging them out of the database either.
          return unless uri

          hash = model.to_jsonmodel(sequel_obj.id).to_hash(:trusted)
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

        # Store our association on the nested record's model so we can walk back
        # the other way.
        ArchivesSpaceService.loaded_hook do
          nested_model = Kernel.const_get(opts[:association][:class_name])
          nested_model.add_enclosing_association(opts[:association])
        end

        nested_records << opts
      end


      # Record the association of the record that encloses this one.  For
      # example, an Archival Object encloses an Instance record because an
      # Instance is a nested record of an Archival Object.
      def add_enclosing_association(association)
        @enclosing_associations ||= []
        @enclosing_associations << association
      end

      # If this is a nested record, return the list of associations that link us
      # back to our parent(s).  Top-level records just return an empty list.
      def enclosing_associations
        @enclosing_associations || []
      end


      def get_nested_graph
        Hash[nested_records.map {|nested_record|
               model = Kernel.const_get(nested_record[:association][:class_name])
               association = nested_record[:corresponding_to_association]

               [association, model.get_nested_graph]
             }]
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
            enums << {:property => prop, :uses_enum => [defn['dynamic_enum']]}
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


      def sequel_to_jsonmodel(objs, opts = {})
        NestedRecordResolver.new(nested_records, objs).resolve
      end

      def associations_to_eagerly_load
        # Allow subclasses to force eager loading of certain associations to
        # save SQL queries.
        []
      end


      def to_jsonmodel(obj, opts = {})
        if obj.is_a? Integer
          # An ID.  Get the Sequel row for it.
          ds = if self.model_scope == :repository
                 self.this_repo
               else
                 self
               end

          obj = ds.eager(get_nested_graph).filter(:id => obj).all[0]
          raise NotFoundException.new("#{self} not found") unless obj

          obj.eagerly_load!
        end

        sequel_to_jsonmodel([obj], opts)[0]
      end


      def handle_delete(ids_to_delete)
        self.filter(:id => ids_to_delete).delete
      end


      def update_mtime_for_repo_id(repo_id)
        if model_scope == :repository
          self.dataset.filter(:repo_id => repo_id).update(:system_mtime => Time.now)
        end
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


      def is_relationship?
        false
      end

    end
  end

end
