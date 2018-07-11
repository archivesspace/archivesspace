class LargeTreeClassification

  def root(response, root_record)
    response['identifier'] = root_record.identifier
    response
  end

  def node(response, node_record)
    response['identifier'] = node_record.identifier
    response
  end

  def waypoint(response, record_ids)
    # Add identifier to nodes
    ClassificationTerm
        .filter(:classification_term__id => record_ids)
        .select(Sequel.as(:classification_term__id, :id),
                Sequel.as(:classification_term__identifier, :identifier))
        .each do |row|

      id = row[:id]
      result_for_record = response.fetch(record_ids.index(id))
      result_for_record['identifier'] = row[:identifier]
    end

    response
  end

end
