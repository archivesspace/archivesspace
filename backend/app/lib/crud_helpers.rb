module CrudHelpers

  def handle_update(model, id, jsonmodel, opts = {})
    obj = model.get_or_die(params[id])
    obj.update_from_json(params[jsonmodel], opts)

    updated_response(obj, params[jsonmodel])
  end


  def handle_create(model, jsonmodel)
    obj = model.create_from_json(params[jsonmodel])

    created_response(obj, params[jsonmodel])
  end


  def handle_listing(model, type, where = {})
    dataset = (model.model_scope == :repository) ? model.this_repo : model

    json_response((where.empty? ? dataset : dataset.filter(where)).collect {|acc|
                    model.to_jsonmodel(acc, type).to_hash
                  })
  end

end
