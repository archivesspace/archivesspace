class IDLookup

  def find_by_ids(model, params)
    filters = {:repo_id => params[:repo_id]}

    params.each do |key, values|
      unless key == :repo_id || key == :resolve
        # The identifier for a resource needs to be massaged to match the db
        if !Array(values).empty? && key == :identifier
          identifiers = Array(values).map {|identifier|
            parsed = ASUtils.json_parse(identifier)
            if parsed.is_a?(Array) && parsed.length > 0 && parsed.length <= 4
              padded = (parsed + ([nil] * 3)).take(4)
              ASUtils.to_json(padded)
            end
          }.compact
          filters[key] = Array(identifiers)
        # For cases other than resources
        elsif !Array(values).empty?
          filters[key] = Array(values)
        end
      end
    end

    return [] if filters.empty?

    model.filter(filters).select(:id).map {|record|
      {'ref' => record.uri}
    }
  end

end
