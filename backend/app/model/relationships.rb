module Relationships

  def self.included(base)
    base.extend(ClassMethods)
  end


  def self.relationship_instances(relationship, obj)
    linked_objects = relationship[:references].map {|linked_model, relationship_model|
      # Walk over each relationship instance
      (obj.send(relationship_model.table_name) or []).map {|relationship_instance|
        [relationship_instance.values, relationship_instance.send(linked_model.table_name)]
      }
    }.flatten(1)

    linked_objects.sort_by {|relationship_properties, _|
      relationship_properties[:aspace_relationship_position]
    }
  end



  def update_from_json(json, opts = {})
    obj = super
    self.class.apply_relationships(obj, json, opts)
    obj
  end


  # Return all instances of the relationship named by 'name'.
  def my_relationships(name)
    relationship = self.class.find_relationship(name)

    Relationships::relationship_instances(relationship, self)
  end


  def delete_all_relationships
    self.class.delete_existing_relationships(self)
  end


  # Return all object instances that are related to the current record by the
  # relationship named by 'name'.
  def linked_records(name)
    my_relationships(name).map {|instance| instance[1]}
  end


  module ClassMethods

    # Define a new relationship.
    def define_relationship(opts)
      [:name, :json_property, :contains_references_to_types].each do |p|
        opts[p] or raise "No #{p} given"
      end

      ArchivesSpaceService.loaded_hook do
        # We hold off actually setting anything up until all models have been
        # loaded, since our relationships may need to reference a model that
        # hasn't been loaded yet.
        #
        # This is also why the :contains_references_to_types property is a proc
        # instead of a regular array--we don't want to blow up with a NameError
        # if the model hasn't been loaded yet.

        relationship = opts.clone
        linked_models = opts[:contains_references_to_types].call

        classes = linked_models.map do |referent|
          # Generate an ugly table name by combining the referring table, the
          # link name and the table it refers to.
          table_name = [self.shortname, referent.shortname].sort.join("_#{relationship[:name]}_").intern
          referrer_table = self.table_name

          begin
            clz = Object.const_get(table_name.to_s.classify)
          rescue NameError
            clz = Class.new(Sequel::Model(table_name)) do
              many_to_one referrer_table
              many_to_one referent.table_name

              if !self.db.table_exists?(self.table_name)
                Log.warn("Table doesn't exist: #{self.table_name}")
              end
            end

            Object.const_set(table_name.to_s.classify, clz)
          end

          self.one_to_many(table_name, :order => "#{table_name}__id".intern)

          clz
        end

        relationship[:references] = Hash[linked_models.zip(classes)]

        @relationships ||= []
        @relationships << relationship
      end
    end


    # Find the relationship named by 'relationship_name'
    def find_relationship(relationship_name)
      @relationships.find {|r| r[:name] == relationship_name} or
        raise "Couldn't find relationship: #{relationship_name}"
    end


    # The list of referent models declared by the relationship names by
    # 'relationship_name'
    def linked_models(relationship_name)
      find_relationship(relationship_name)[:references].keys
    end


    # Delete all existing relationships for 'obj'.
    def delete_existing_relationships(obj)
      @relationships.each do |relationship|
        relationship[:references].values.each do |relationship_model|
          obj.send("#{relationship_model.table_name}_dataset".intern).delete
        end
      end
    end


    def apply_relationships(obj, json, opts)
      delete_existing_relationships(obj)

      @relationships.each do |relationship|
        property_name = relationship[:json_property]

        # For each record reference in our JSON data
        Array(json[property_name]).each_with_index do |reference, idx|
          record_type = parse_reference(reference['ref'], opts)

          # Find the model type of the record it refers to
          referent_model = relationship[:references].keys.find {|model|
            model.my_jsonmodel.record_type == record_type[:type]
          } or raise "Couldn't find model for #{record_type[:type]}"

          # Find the model type that represents the relationship between us and
          # them
          link_model = relationship[:references][referent_model]

          # Create a new relationship instance linking us and them together, and
          # add the properties from the JSON request to the relationship
          properties = reference.clone.tap do |properties|
            properties.delete('ref')
          end

          properties[self.table_name] = obj
          properties[referent_model.table_name] = referent_model[record_type[:id]]
          properties[:aspace_relationship_position] = idx

          link_model.create(properties)
        end
      end
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_relationships(obj, json, opts)
      obj
    end


    def sequel_to_jsonmodel(obj, opts = {})
      json = super

      @relationships.each do |relationship|
        property_name = relationship[:json_property]

        # For each defined relationship
        linked_objects = Relationships::relationship_instances(relationship, obj)

        json[property_name] = linked_objects.map {|relationship_properties, referent|
          # Return the relationship properties, plus the URI reference of the
          # related object
          values = ASUtils.keys_as_strings(relationship_properties.clone)
          values['ref'] = referent.uri

          values
        }
      end

      json
    end


    # Find all instances of the referring class that have a relationship with 'obj'
    def instances_relating_to(obj)
      @relationships.map do |relationship|
        relationship_model = relationship[:references][obj.class]

        if !relationship_model
          []
        else
          # This relationship links to records with the same type as 'obj'
          relationship_model.filter("#{obj.class.table_name}_id".intern => obj.id).map {|r|
            # Yield the instance of self that relates to obj
            r.send(self.table_name)
          }
        end
      end.flatten
    end

    def prepare_for_deletion(dataset)
      dataset.each do |obj|
        obj.delete_all_relationships
      end

      super
    end

  end
end
