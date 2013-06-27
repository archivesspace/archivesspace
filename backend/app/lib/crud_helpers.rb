module CrudHelpers

  def handle_update(model, id, parameter, opts = {})
    obj = model.get_or_die(params[id])
    obj.update_from_json(params[parameter], opts)

    updated_response(obj, params[parameter])
  end


  def handle_create(model, parameter, opts = {})
    obj = model.create_from_json(params[parameter], opts)

    created_response(obj, params[parameter])
  end


  def handle_delete(model, id)
    obj = model.get_or_die(id)
    obj.delete

    deleted_response(id)
  end


  def self.dataset(model, where_clause)
    dataset = (model.model_scope == :repository) ? model.this_repo : model

    if where_clause.is_a?(Hash) && where_clause.has_key?(:exclude)
      dataset = dataset.exclude(where_clause[:exclude])
      where_clause.delete(:exclude)
    end

    if !where_clause.is_a?(Hash) || !where_clause.empty?
      dataset = dataset.filter(where_clause)
    end

    dataset
  end


  def _listing_response(dataset, model)
    results = dataset.collect {|obj|
      json = model.to_jsonmodel(obj)

      if params[:resolve]
        resolve_references(json, params[:resolve])
      else
        json
      end
    }

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


  def handle_listing(model, pagination_data, where = {})

    dataset = CrudHelpers.dataset(model, where)

    modified_since_time = Time.at(pagination_data[:modified_since])
    dataset = dataset.where { system_mtime >= modified_since_time }

    if pagination_data[:page]
      # Classic pagination mode
      paginated = dataset.paginate(pagination_data[:page], pagination_data[:page_size])

      _listing_response(paginated, model)

    elsif pagination_data[:all_ids]
      # Return a JSON array containing all IDs for the matching records
      json_response(dataset.select(:id).map {|rec| rec[:id]})

    elsif pagination_data[:id_set]
      # Return the requested set of IDs
      _listing_response(dataset.filter(:id => pagination_data[:id_set]).all, model)
    end
  end

end
