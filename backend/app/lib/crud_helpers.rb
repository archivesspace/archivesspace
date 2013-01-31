module CrudHelpers

  def handle_update(model, id, parameter, opts = {})
    obj = model.get_or_die(params[id])
    obj.update_from_json(params[parameter], opts)

    updated_response(obj, params[parameter])
  end


  def handle_create(model, parameter)
    obj = model.create_from_json(params[parameter])

    created_response(obj, params[parameter])
  end


  def handle_delete(model, id)
    obj = model.get_or_die(id)
    obj.delete

    deleted_response(id)
  end


  def self.dataset(model, where_clause)
    dataset = (model.model_scope == :repository) ? model.this_repo : model

    if where_clause.has_key?(:exclude)
      dataset = dataset.exclude(where_clause[:exclude])
      where_clause.delete(:exclude)
    end
    
    if !where_clause.empty?    
      dataset = dataset.filter(where_clause)
    end

    dataset
  end


  def _listing_response(dataset, model)
    results = dataset.collect {|obj| model.to_jsonmodel(obj)}

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


  def handle_unlimited_listing(model, where = {})
    dataset = CrudHelpers.dataset(model, where)

    _listing_response(dataset, model)
  end


  def handle_listing(model, page, page_size, modified_since, where = {})

    dataset = CrudHelpers.dataset(model, where)

    modified_since_time = Time.at(modified_since)
    dataset = dataset.where { last_modified >= modified_since_time }

    paginated = dataset.paginate(page, page_size)

    _listing_response(paginated, model)
  end

end
