class IDLookup

  def find_by_ids(model, params)
    filters = {}

    params.each do |key, values|
      next if Array(values).empty?

      key = key.intern

      # We're not searching on these values
      next if [:repo_id, :resolve].include?(key)

      # The identifier for a resource needs to be massaged to match the db
      if key == :identifier
        identifiers = Array(values).map {|identifier|
          parsed = ASUtils.json_parse(identifier)
          if parsed.is_a?(Array) && parsed.length > 0 && parsed.length <= 4
            padded = (parsed + ([nil] * 3)).take(4)
            ASUtils.to_json(padded)
          end
        }.compact
        filters[key] = Array(identifiers)
      elsif key == :ark
        # ARKs will be contained in ark_name.ark_value and will link back to a record by
        # foreign key.  Find those and build a filter that pulls back the linked records
        # by their primary key.
        fk_col = :"#{model.table_name}_id"
        filters[:id] = ArkName.filter(:ark_value => values).map(fk_col)
      else
        filters[key] = Array(values)
      end
    end

    return [] if filters.empty?

    model.this_repo.where(filters).select(:id).map {|record|
      {'ref' => record.uri}
    }
  end

end
