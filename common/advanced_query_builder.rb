class AdvancedQueryBuilder

  def initialize(queries, visibility)
    @queries = queries
    @visibility = visibility

    raise "Invalid visibility value: #{visibility}" unless [:staff, :public].include?(visibility)
    validate_queries!
  end


  def build_query
    query = if @queries.length > 1
      stack = @queries.reverse.clone

      while stack.length > 1
        a = stack.pop
        b = stack.pop

        stack.push(JSONModel(:boolean_query).from_hash({
                                                         :op => b["op"],
                                                         :subqueries => [as_subquery(a), as_subquery(b)]
                                                       }))
      end

      stack.pop
    else
      as_subquery(@queries[0])
    end

    JSONModel(:advanced_query).from_hash({"query" => query})
  end


  private

  def validate_queries!
    @queries.each do |query|
      invalid = AdvancedSearch.fields_matching(:name => query['field'],
                                               :visibility => @visibility,
                                               :type => query['type']).empty?
      raise "Invalid query: #{query.inspect}" if invalid
    end
  end

  def as_subquery(query_data)
    if query_data.kind_of? JSONModelType
      query_data
    elsif query_data["type"] == "date"
      JSONModel(:date_field_query).from_hash(query_data)
    elsif query_data["type"] == "boolean"
      JSONModel(:boolean_field_query).from_hash(query_data)
    else
      query = JSONModel(:field_query).from_hash(query_data)

      if query_data["type"] == "enum"
        query.literal = true
      end

      query
    end
  end

end
