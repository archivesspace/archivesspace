module AgentNames

  def self.included(base)
    base.set_model_scope :global
    
    base.one_to_many :date, :class => "ASDate"
    
    base.def_nested_record(:the_property => :use_dates,
                           :contains_records_of_type => :date,
                           :corresponding_to_association => :date)


    base.one_to_one :name_authority_id

    base.extend(ClassMethods)
  end


  def before_validation
    super

    # force to NULL (not 0) to make sure uniqueness constraints work as
    # desired.
    self.authorized = nil if self.authorized != 1
    self.is_display_name = nil if self.is_display_name != 1
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    self.class.apply_authority_id(obj, json)
  end



  module ClassMethods

    def calculate_object_graph(object_graph, opts = {})
      super

      # Add the rows for authority IDs too
      column = "#{self.table_name}_id".intern

      ids = NameAuthorityId.filter(column => object_graph.ids_for(self)).
                            map {|row| row[:id]}

      object_graph.add_objects(NameAuthorityId, ids)
    end


    def associations_to_eagerly_load
      super + [:name_authority_id]
    end

    def apply_authority_id(obj, json)
      obj.name_authority_id_dataset.delete

      if json['authority_id']
        obj.name_authority_id = NameAuthorityId.create(:authority_id => json['authority_id'],
                                                       :lock_version => 0)
      end

      obj
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_authority_id(obj, json)
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        if obj.name_authority_id
          json['authority_id'] = obj.name_authority_id.authority_id
        end
      end

      jsons
    end


    def assemble_hash_fields(json)
      name = my_jsonmodel.from_hash(json)
      hash_fields = []
      name_fields = %w(dates qualifier source rules) + type_specific_hash_fields

      name['use_dates'].each do |date|
        hash_fields << [:date_type,
                        :label, 
                        :certainty,
                        :expression, 
                        :begin, 
                        :end, 
                        :era, 
                        :calendar].map {|property|
          date[property.to_s] || ' '
        }.join('_')
      end


      hash_fields << name_fields.uniq.map {|property|
        if !name[property]
          ' '
        elsif name.class.schema["properties"][property]["dynamic_enum"]
          enum = name.class.schema["properties"][property]["dynamic_enum"]
          BackendEnumSource.id_for_value(enum, name[property])
        else
          name[property.to_s]
        end
      }.join('_')

      hash_fields

    end
  end

end
