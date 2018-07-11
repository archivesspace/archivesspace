require_relative "../model/ASModel_database_mapping"

class NestedRecordResolver

  include ASModel::DatabaseMapping
  include JSONModel

  def initialize(nested_records, objs)
    @nested_records = nested_records
    fully_loaded_objs = load_with_all_associations(objs).clone

    # We pull a bit of a trick here: replace the set of Sequel::Model instances
    # we were passed with an equivalent set that have all of the nested records
    # already loaded in.  That way, subsequent calls will have the data they
    # need.
    #
    # Unfortunately the current interface requires us to mutate the array
    # in-place, since there's no easy way to replace the set of objects with the
    # current sequel_to_json API.
    objs.clear
    objs.concat(fully_loaded_objs)
    @objs = objs
  end


  def resolve
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

        nested_objs = Array(obj.send(nested_record[:association][:name]))

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

  def load_with_all_associations(objs)
    # Eagerly load all of the associations of the set of top-level objects we're
    # asked to resolve.

    return objs if objs.empty?

    model = objs[0].class
    graph = nested_record_association_graph(model)

    if graph.empty?
      objs
    else
      if graph.keys.all? {|association| objs.all? {|obj| obj.associations.has_key?(association)}}
        # All loaded separately.  No need to redo it.
        objs
      else
        loaded = model.any_repo.eager(graph).filter(:id => objs.map(&:id)).all

        # return the objects in the same order in which we received them
        # some callers care about the order!
        loaded.sort_by { |loaded_obj| objs.index {|obj| obj.id == loaded_obj.id} }
      end
    end
  end


  # Create a graph of all Sequel associations starting with `model`.  Passed to
  # `eager` to eagerly fetch the rows we know we'll need.
  def nested_record_association_graph(model)
    result = {}

    model.nested_records.each do |nested_record|
      association = nested_record[:association]
      next unless [:one_to_one, :one_to_many].include?(association[:type])

      nested_model = Kernel.const_get(association[:class_name])
      result[association[:name]] = nested_record_association_graph(nested_model)
    end


    # Add any extras that were marked too
    model.associations_to_eagerly_load.each do |association_name|
      result[association_name] ||= {}
    end

    result
  end

  attr_reader :nested_records
end
