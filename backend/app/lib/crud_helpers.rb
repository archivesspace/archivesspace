module CrudHelpers

  def handle_update(model, id, jsonmodel)
    obj = model.get_or_die(params[id], params[:repo_id])
    obj.update_from_json(params[jsonmodel])

    updated_response(obj, params[jsonmodel])
  end


  def handle_create(model, jsonmodel)
    obj = model.create_from_json(params[jsonmodel],
                                 :repo_id => params[:repo_id])

    created_response(obj, params[jsonmodel])
  end


  def handle_listing(model, type, where = {})
    json_response((where.empty? ? model : model.filter(where)).collect {|acc|
                    model.to_jsonmodel(acc, type).to_hash
                  })
  end

end
