require_relative "../model/ASModel_database_mapping"

class NestedRecordResolver

  include ASModel::DatabaseMapping
  include JSONModel

  def initialize(nested_records, objs)
    @nested_records = nested_records
    @objs = objs
  end


  def resolve
    preload_nested_records
    do_resolve
  end


  private

  def do_resolve
    # Walk across the objects we're resolving, link their nested records
    # back to them, and turn whole lot into JSONModels.
    @objs.map {|obj|
      jsonmodel = obj.class.my_jsonmodel
      json = jsonmodel.new(self.class.map_db_types_to_json(jsonmodel.schema,
                                                           obj.values.reject {|k, v| v.nil? }))

      uri = jsonmodel.uri_for(obj.id, :repo_id => obj.class.active_repository)
      json.uri = uri if uri

      if obj.class.model_scope == :repository
        json['repository'] = {'ref' => JSONModel(:repository).uri_for(obj.class.active_repository)}
      end

      # If there are nested records for this class, insert them into our
      # JSON structure here.
      nested_records.each do |nested_record|
        model = Kernel.const_get(nested_record[:association][:class_name])

        if [:one_to_one, :one_to_many].include?(nested_record[:association][:type])
          nested_objs = nested_records_for(nested_record[:json_property], obj)
        else
          nested_objs = Array(obj.send(nested_record[:association][:name]))
        end
        
        unless nested_record[:association][:order]
          nested_objs.sort_by!{ |rec| rec[:id] }
        end
       
        records = model.sequel_to_jsonmodel(nested_objs).map {|rec|
          rec.to_hash(:trusted)
        }

        is_array = nested_record[:is_array] && ![:many_to_one, :one_to_one].include?(nested_record[:association][:type])

        json[nested_record[:json_property]] = (is_array ? records : records[0])
      end

      ASModel::CRUD.set_audit_fields(json, obj)

      json
    }
  end


  def nested_records_for(property, obj)
    @all_nested.fetch(property, {}).fetch(obj.id, [])
  end


  def preload_nested_records
    @all_nested = {}

    # Load all nested records into memory, doing all of our DB querying up
    # front (and efficiently)
    nested_records.each do |nested_record|
      objs_ids = @objs.map(&:id)
      next if objs_ids.empty?

      @all_nested[nested_record[:json_property]] ||= {}

      association = nested_record[:association]

      next unless [:one_to_one, :one_to_many].include?(association[:type])

      model = Kernel.const_get(association[:class_name])
      matches = model.filter(association[:key] => objs_ids)

      matches.each do |nested_obj|
        @all_nested[nested_record[:json_property]][nested_obj[association[:key]]] ||= []
        @all_nested[nested_record[:json_property]][nested_obj[association[:key]]] << nested_obj
      end
    end
  end


  attr_reader :nested_records
end
