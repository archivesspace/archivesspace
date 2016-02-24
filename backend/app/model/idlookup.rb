class IDLookup

  def find_by_ids(model, id_maps)
    filters = {}

    id_maps.each do |column, ids|
      if !Array(ids).empty?
        filters[column] = Array(ids)

      end
    end

    return [] if filters.empty?

    model.filter(filters).select(:id).map {|record|
      {'ref' => record.uri}
    }
  end

end
