# We'll create a concrete instance of this class for each defined relationship.
AbstractRelationship = Class.new(Sequel::Model) do

  def self.relate(obj1, obj2, properties)
    columns = if obj1.class == obj2.class
      # If our two related objects are of the same type, we'll get back multiple
      # columns here anyway
      raise ReferenceError.new("Can't relate an object to itself") if obj1.id == obj2.id

      self._reference_columns_for(obj1.class)
    else
      [self._reference_columns_for(obj1.class).first, self._reference_columns_for(obj2.class).first]
    end

    self.create(Hash[columns.zip([obj1.id, obj2.id])].merge(properties))
  end


  def self.to_s
    "<#Relationship #{table_name}>"
  end

  def self.set_json_property(property); @json_property = property; end
  def self.json_property; @json_property; end


  def self.set_participating_models(models); @participating_models = models; end
  def self.participating_models; @participating_models or raise "No participating models set"; end


  def self.set_wants_array(val); @wants_array = val; end
  def self.wants_array?; @wants_array; end


  # Return a list of the relationship instances involving 'obj'.
  def self.find_by_participant(obj)
    # Find all columns in our relationship's table that are named after obj's table
    # These will contain references to instances of obj's class
    reference_columns = self._reference_columns_for(obj.class)
    matching_relationships = reference_columns.map {|col| self.filter(col => obj.id).all}.flatten(1)
    matching_relationships.sort_by {|relationship| relationship[:aspace_relationship_position]}
  end


  # Return a list of the objects that are related to 'obj' via one of our
  # relationships
  def self.who_participates_with(obj)
    # Find all relationships involving obj
    relationships = self.find_by_participant(obj)

    relationships.map {|relationship|
      relationship.other_referent_than(obj)
    }
  end


  def self._reference_columns_for(model)
    self.db_schema.keys.select { |column_name|
      column_name.to_s.downcase =~ /\A#{model.table_name.downcase}_id(_[0-9]+)?\z/
    }
  end


  def properties
    self.values
  end


  def other_referent_than(obj)
    self.class.participating_models.each {|model|
      self.class._reference_columns_for(model).each {|column|
        if self[column] && (model != obj.class || self[column] != obj.id)
          return model.respond_to?(:any_repo) ? model.any_repo[self[column]] : model[self[column]]
        end
      }
    }

    nil
  end

end


module Relationships

  def self.included(base)
    base.instance_eval do
      @relationships ||= {}
      @relationship_dependencies ||= []
    end

    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    obj = super
    self.class.apply_relationships(obj, json, opts)
    obj
  end


  # Added to the mixed in class itself: return a list of the relationship
  # instances involving this object
  def my_relationships(name)
    self.class.find_relationship(name).find_by_participant(self)
  end


  # Return all object instances that are related to the current record by the
  # relationship named by 'name'.
  def linked_records(name)
    relationship = self.class.find_relationship(name)
    records = relationship.who_participates_with(self)

    relationship.wants_array? ? records : records.first
  end


  module ClassMethods

    # Reset relationship definitions for the current class
    def clear_relationships
      @relationships = {}
    end


    def find_relationship(name)
      @relationships[name] or raise "Couldn't find #{name} in #{@relationships.inspect}"
    end

    # Define a new relationship.
    def define_relationship(opts)
      [:name, :json_property, :contains_references_to_types].each do |p|
        opts[p] or raise "No #{p} given"
      end

      base = self

      ArchivesSpaceService.loaded_hook do
        # We hold off actually setting anything up until all models have been
        # loaded, since our relationships may need to reference a model that
        # hasn't been loaded yet.
        #
        # This is also why the :contains_references_to_types property is a proc
        # instead of a regular array--we don't want to blow up with a NameError
        # if the model hasn't been loaded yet.


        linked_models = opts[:contains_references_to_types].call

        clz = Class.new(AbstractRelationship) do
          table = "#{opts[:name]}_rlshp".intern
          set_dataset(table)
          set_primary_key(:id)

          if !self.db.table_exists?(self.table_name)
            Log.warn("Table doesn't exist: #{self.table_name}")
          end

          set_participating_models([base, *linked_models].uniq)
          set_json_property(opts[:json_property])
          set_wants_array(opts[:is_array].nil? || opts[:is_array])
        end

        opts[:class_callback].call(clz) if opts[:class_callback]

        @relationships[opts[:name]] = clz

        linked_models.each do |model|
          model.include(Relationships)
          model.add_relationship_dependency(base)
        end
      end
    end


    # Delete all existing relationships for 'obj'.
    def delete_existing_relationships(obj)
      @relationships.values.each do |relationship_defn|
        relationship_defn.find_by_participant(obj).each(&:delete)
      end
    end


    # Create set of relationships for a given update
    def apply_relationships(obj, json, opts, new_record = false)
      delete_existing_relationships(obj) if !new_record

      @relationships.values.each do |relationship_defn|
        property_name = relationship_defn.json_property

        # For each record reference in our JSON data
        ASUtils.as_array(json[property_name]).each_with_index do |reference, idx|
          record_type = parse_reference(reference['ref'], opts)

          referent_model = relationship_defn.participating_models.find {|model|
            model.my_jsonmodel.record_type == record_type[:type]
          } or raise "Couldn't find model for #{record_type[:type]}"

          referent = referent_model[record_type[:id]]

          if !referent
            raise ReferenceError.new("Can't link to non-existent record: #{reference['ref']}")
          end

          # Create a new relationship instance linking us and them together, and
          # add the properties from the JSON request to the relationship
          properties = reference.clone.tap do |properties|
            properties.delete('ref')
          end

          properties[:aspace_relationship_position] = idx
          properties[:last_modified] = Time.now

          relationship_defn.relate(obj, referent, properties)

          DB.increase_lock_version_or_fail(referent) unless opts[:system_generated]
        end
      end
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_relationships(obj, json, opts, true)
      obj
    end


    def sequel_to_jsonmodel(obj, opts = {})
      json = super

      @relationships.values.each do |relationship_defn|
        property_name = relationship_defn.json_property

        # For each defined relationship
        relationships = relationship_defn.find_by_participant(obj)

        json[property_name] = relationships.map {|relationship|
          # Return the relationship properties, plus the URI reference of the
          # related object
          values = ASUtils.keys_as_strings(relationship.properties)
          values['ref'] = relationship.other_referent_than(obj).uri

          values
        }

        if !relationship_defn.wants_array?
          json[property_name] = json[property_name].first
        end
      end

      json
    end


    # Find all instances of the referring class that have a relationship with 'obj'
    # Spans all defined relationships.
    def instances_relating_to(obj)
      @relationships.values.map {|relationship_defn|
        relationship_defn.who_participates_with(obj)
      }.flatten
    end


    def add_relationship_dependency(clz)
      @relationship_dependencies << clz
    end


    def prepare_for_deletion(dataset)
      dataset.each do |obj|
        # Delete all the relationships created against this object
        delete_existing_relationships(obj)
        @relationship_dependencies.each do |model|
          model.delete_existing_relationships(obj) if model != self
        end
      end

      super
    end

  end
end
