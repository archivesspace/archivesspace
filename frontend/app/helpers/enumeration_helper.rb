module EnumerationHelper

  def enumeration_advanced_query(relationships, value)
    queries = []

    relationships.map {|rel|
      queries << JSONModel(:field_query).from_hash({
        'field' => "#{rel}_enum_s",
        'value' => value
      })
    }

    JSONModel(:advanced_query).from_hash({
      'query' => JSONModel(:boolean_query).from_hash({
        'subqueries' => queries,
        'op' => 'OR'
      })
    })
  end

end

