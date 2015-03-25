module CrudHelpers

  def handle_update(model, id, json, opts = {})
    obj = model.get_or_die(id)
    obj.update_from_json(json, opts)

    updated_response(obj, json)
  end


  def handle_create(model, json, opts = {})
    obj = model.create_from_json(json, opts)

    created_response(obj, json)
  end


  def handle_delete(model, id)
    obj = model.get_or_die(id)
    obj.delete

    deleted_response(id)
  end


  def self.scoped_dataset(model, where_clause)
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


  def handle_unlimited_listing(model, where = {})
    dataset = CrudHelpers.scoped_dataset(model, where)

    listing_response(dataset, model)
  end


  def handle_listing(model, pagination_data, where = {}, order = nil)

    dataset = CrudHelpers.scoped_dataset(model, where)

    modified_since_time = Time.at(pagination_data[:modified_since])
    dataset = dataset.where { system_mtime >= modified_since_time }
    dataset = dataset.order(*order) if order

    if pagination_data[:page]
      # Classic pagination mode
      paginated = dataset.extension(:pagination).paginate(pagination_data[:page], pagination_data[:page_size])

      listing_response(paginated, model)

    elsif pagination_data[:all_ids]
      # Return a JSON array containing all IDs for the matching records
      json_response(dataset.select(:id).map {|rec| rec[:id]})

    elsif pagination_data[:id_set]
      # Return the requested set of IDs
      listing_response(dataset.filter(:id => pagination_data[:id_set]), model)
    end
  end

  private

  def listing_response(dataset, model)

    objs = dataset.respond_to?(:all) ? dataset.all : dataset
    jsons = model.sequel_to_jsonmodel(objs).map {|json|
      if json.is_a?(JSONModelType)
        json.to_hash(:trusted)
      else
        json
      end
    }

    results = resolve_references(jsons, params[:resolve])

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

end
