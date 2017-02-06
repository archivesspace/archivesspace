class AdvancedQueryBuilder

  attr_reader :query

  def initialize
    @query = nil
  end

  def and(field_or_subquery, value = nil, type = 'text', literal = false, negated = false)
    if field_or_subquery.is_a?(AdvancedQueryBuilder)
      push_subquery('AND', field_or_subquery)
    else
      raise "Missing value" unless value
      push_term('AND', field_or_subquery, value, type, literal, negated)
    end

    self
  end

  def or(field_or_subquery, value = nil, type = 'text', literal = false, negated = false)
    if field_or_subquery.is_a?(AdvancedQueryBuilder)
      push_subquery('OR', field_or_subquery)
    else
      raise "Missing value" unless value
      push_term('OR', field_or_subquery, value, type, literal, negated)
    end

    self
  end

  def empty?
    @query.nil?
  end

  def build
    JSONModel::JSONModel(:advanced_query).from_hash({"query" => build_query(@query)})
  end

  def self.from_json_filter_terms(array_of_json)
    builder = new

    array_of_json.each do |json_str|
      json = ASUtils.json_parse(json_str)
      builder.and(json.keys[0], json.values[0])
    end

    builder.build
  end

  def self.build_query_from_form(queries)

    query = if queries.length > 1
      stack = queries.reverse.clone

      while stack.length > 1
        a = stack.pop
        b = stack.pop

        stack.push(JSONModel::JSONModel(:boolean_query).from_hash({
                                                         :op => b["op"],
                                                         :subqueries => [as_field_query(a), as_field_query(b)]
                                                       }))
      end

      stack.pop
    else
      as_field_query(queries[0])
    end

    JSONModel::JSONModel(:advanced_query).from_hash({"query" => query})
  end


  private

  def push_subquery(operator, subquery)
    new_query = {
      :operator => operator,
      :type => 'boolean_query',
      :arg1 => subquery.query,
      :arg2 => @query,
    }

    @query = new_query
  end

  def push_term(operator, field, value, type = 'text', literal = false, negated = false)
    new_query = {
      :operator => operator,
      :type => 'boolean_query',
      :arg1 => {
        :field => field,
        :value => value,
        :type => type,
        :negated => negated,
        :literal => literal,
      },
      :arg2 => @query,
    }

    @query = new_query
  end

  def build_query(query)
    if query[:type] == 'boolean_query'
      subqueries = [query[:arg1], query[:arg2]].compact.map {|subquery|
        build_query(subquery)
      }

      JSONModel::JSONModel(:boolean_query).from_hash({
                                            :op => query[:operator],
                                            :subqueries => subqueries
                                          })
    else
      self.class.as_field_query(query)
    end
  end

  def self.as_field_query(query_data)
    if query_data.kind_of?(JSONModelType)
      query_data
    elsif query_data["type"] == "date"
      JSONModel::JSONModel(:date_field_query).from_hash(query_data)
    elsif query_data["type"] == "boolean"
      JSONModel::JSONModel(:boolean_field_query).from_hash(query_data)
    else
      query = JSONModel::JSONModel(:field_query).from_hash(query_data)

      if query_data["type"] == "enum"
        query.literal = true
      end

      query
    end
  end

end
