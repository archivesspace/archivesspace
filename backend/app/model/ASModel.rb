module ASModel
  include JSONModel

  @@linked_records = {}

  def self.linked_records
    @@linked_records
  end


  def before_create
    self.create_time = Time.now
    self.last_modified = Time.now
    super
  end


  def before_update
    self.last_modified = Time.now
    super
  end


  def self.included(base)
    base.extend(ClassMethods)
    base.extend(JSONModel)
  end


  def update_from_json(json, opts = {})
    old = JSONModel(json.class.record_type).from_hash(json.to_hash.merge(self.values)).to_hash
    changes = json.to_hash.merge(opts)

    old.each do |k, v|
      if not changes.has_key?(k)
        changes[k] = nil
      end
    end

    self.class.strict_param_setting = false
    self.update(changes)
    id = self.save

    self.class.apply_linked_database_records(self, json, opts)

    id
  end

  module ClassMethods

    # Define a linkage between two record types.
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
    #  For example, a definition like this one in the subject.rb model:
    #
    #   define_linked_record(:type => :term,
    #                        :plural_type => :terms,
    #                        :class => Term,
    #                        :always_inline => true)
    #
    # Causes an incoming JSONModel(:subject) to have each of the objects in its
    # "terms" array to be coerced into a Sequel model of type Term and stored in
    # the database.  The provided list of terms are associated with the subject
    # as it is stored, and these replace any previous terms.
    #
    # The definition also causes Subject.to_jsonmodel(obj, :subject) to
    # automatically pull back the list of terms associated with the object and
    # include them in the response.  Here, the :always_inline parameter
    # indicates that we want the actual JSON objects to be included in the
    # response, not just their URI references.
    #
    def define_linked_record(opts)
      ASModel.linked_records[self] ||= []
      ASModel.linked_records[self] << opts
    end


    def create_from_json(json, extra_values = {})
      self.strict_param_setting = false
      obj = self.create(json.to_hash.merge(extra_values))

      self.apply_linked_database_records(obj, json, extra_values)

      obj
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
    def apply_linked_database_records(obj, json, opts)
      (ASModel.linked_records[self] or []).each do |linked_record|
        # Remove the existing linked records
        obj.send("remove_all_#{linked_record[:plural_type]}".intern)

        # Read the subrecords from our JSON blob and fetch or create
        # the corresponding subrecord from the database.
        model = linked_record[:class]

        records = (json.send(linked_record[:plural_type]) or []).map do |json_or_uri|

          if json_or_uri.kind_of? String
            # A URI.  Just grab its database ID.
            JSONModel(linked_record[:type]).id_for(json_or_uri)
          else
            # Create a database record for the JSON blob and return its ID
            subrecord_json = JSONModel(linked_record[:type]).from_hash(json_or_uri)

            if model.respond_to? :ensure_exists
              # Give our classes an opportunity to provide their own logic here
              model.ensure_exists(subrecord_json, obj)
            else
              extra_opts = {}

              if linked_record[:foreign_key]
                extra_opts[linked_record[:foreign_key]] = obj.id
              end

              model.create_from_json(subrecord_json, extra_opts).id
            end
          end

        end

        records.each do |record_id|
          obj.send("add_#{linked_record[:type]}", model[record_id])
        end
      end
    end


    def get_or_die(id, repo_id = nil)
      # For a minute there I lost myself...
      obj = repo_id.nil? ? self[id] : self[:id => id, :repo_id => repo_id]

      obj or raise NotFoundException.new("#{self} not found")
    end


    def sequel_to_jsonmodel(obj, model)
      json = JSONModel(model).new(obj.values.reject {|k, v| v.nil? })

      uri = json.class.uri_for(obj.id, {:repo_id => obj[:repo_id]})
      json.uri = uri if uri

      # If there are linked records for this class, grab their URI references too
      (ASModel.linked_records[self] or []).each do |linked_record|

        records = obj.send(linked_record[:plural_type]).map {|linked_obj|
          if linked_record[:always_inline]
            linked_record[:class].to_jsonmodel(linked_obj, linked_record[:type]).to_hash
          else
            JSONModel(linked_record[:type]).uri_for(linked_obj.id) or
              raise "Couldn't produce a URI for record type: #{linked_record[:type]}."
          end
        }

        json.send("#{linked_record[:plural_type]}=".intern, records)
      end

      json
    end


    def to_jsonmodel(obj, model, repo_id = nil)
      if obj.is_a? Integer
        # An ID.  Get the Sequel row for it.
        obj = get_or_die(obj, repo_id)
      end

      sequel_to_jsonmodel(obj, model)
    end

  end
end
