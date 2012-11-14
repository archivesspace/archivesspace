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


  def self.dataset(model, where_clause)
    dataset = (model.model_scope == :repository) ? model.this_repo : model

    if !where_clause.empty?
      dataset = dataset.filter(where_clause)
    end

    dataset
  end


  def _listing_response(dataset, model, type)
    results = dataset.collect {|obj| model.to_jsonmodel(obj, type).to_hash}

    if dataset.respond_to? (:page_range)
      response = {
        :first_page => dataset.page_range.first,
        :last_page => dataset.page_range.last,
        :this_page => dataset.current_page,
        :results => results
      }
    else
      response = results
    end

    json_response(response)
  end


  def handle_unlimited_listing(model, type, where = {})
    dataset = CrudHelpers.dataset(model, where)

    _listing_response(dataset, model, type)
  end


  def handle_listing(model, type, page, page_size, where = {})
    dataset = CrudHelpers.dataset(model, where)

    paginated = dataset.paginate(page, page_size)

    _listing_response(paginated, model, type)
  end

end
