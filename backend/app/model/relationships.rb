module Relationships

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {})
    obj = super
    self.class.apply_relationships(obj, json, opts)
    obj
  end


  def linked_records(name)
    relationship = self.class.find_relationship(name)

    relationship[:references].map do |linked_model, relationship_model|
      self.send(relationship_model.table_name).map do |relationship_instance|
        relationship_instance.send(linked_model.table_name)
      end
    end.flatten
  end


  module ClassMethods

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
          table_name = "#{self.shortname}_#{relationship[:name]}_#{referent.shortname}".intern

          referrer_table = self.table_name

          clz = Class.new(Sequel::Model(table_name)) do
            many_to_one referrer_table
            many_to_one referent.table_name

            if !self.db.table_exists?(self.table_name)
              Log.warn("Table doesn't exist: #{self.table_name}")
            end
          end

          Object.const_set(table_name.to_s.classify, clz)

          # FIXME: add ordering by id
          self.one_to_many(table_name)

          clz
        end

        relationship[:references] = Hash[linked_models.zip(classes)]

        @relationships ||= []
        @relationships << relationship
      end
    end


    def find_relationship(relationship_name)
      @relationships.find {|r| r[:name] == relationship_name} or
        raise "Couldn't find relationship: #{relationship_name}"
    end


    def linked_models(relationship_name)
      find_relationship(relationship_name)[:references].keys
    end


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

        Array(json[property_name]).each do |reference|
          record_type = parse_reference(reference['ref'], opts)

          referent_model = relationship[:references].keys.find {|model|
            model.my_jsonmodel.record_type == record_type[:type]
          } or raise "Couldn't find model for #{record_type[:type]}"

          link_model = relationship[:references][referent_model]

          properties = reference.clone.tap do |properties|
            properties.delete('ref')
          end

          properties[self.table_name] = obj
          properties[referent_model.table_name] = referent_model[record_type[:id]]

          relationship = link_model.create(properties)
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

        json[property_name] ||= []

        relationship[:references].each do |linked_model, relationship_model|
          json[property_name] += obj.send(relationship_model.table_name).map do |relationship_instance|
            referent = relationship_instance.send(linked_model.table_name)

            properties = relationship_instance.values.clone
            properties['ref'] = referent.uri

            properties.delete(:id)
            properties.delete("#{self.table_name}_id".intern)
            properties.delete("#{linked_model.table_name}_id".intern)

            properties
          end
        end
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

  end
end
