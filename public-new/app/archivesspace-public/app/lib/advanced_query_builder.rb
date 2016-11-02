# TODO Please be aware there is also an AdvancedQueryBuilder in the
# ArchivesSpace distribution.  If the new public application is error merged
# with the ArchivesSpace core, then this file can be removed in favour of the
# ArchivesSpace version.

class AdvancedQueryBuilder

  attr_reader :query

  RangeValue = Struct.new(:from, :to)

  def initialize
    @query = nil
  end

  def and(field_or_subquery, value = nil, type = 'text', negated = false)
    if field_or_subquery.is_a?(AdvancedQueryBuilder)
      push_subquery('AND', field_or_subquery)
    elsif value.is_a? RangeValue
      push_range('AND', field_or_subquery, value, 'range', negated)
    else
      raise "Missing value" unless value
      push_term('AND', field_or_subquery, value, type, negated)
    end

    self
  end

  def or(field_or_subquery, value = nil, type = 'text', negated = false)
    if field_or_subquery.is_a?(AdvancedQueryBuilder)
      push_subquery('OR', field_or_subquery)
    elsif value.is_a? RangeValue
      push_range('AND', field_or_subquery, value, 'range', negated)
    else
      raise "Missing value" unless value
      push_term('OR', field_or_subquery, value, type, negated)
    end

    self
  end

  def build
    {
      'jsonmodel_type' => 'advanced_query',
      'query' => build_query(@query)
    }
  end

  def self.from_json_filter_terms(array_of_json)
    builder = new

    array_of_json.each do |json_str|
      json = ASUtils.json_parse(json_str)
      builder.and(json.keys[0], json.values[0])
    end

    builder.build
  end


  private

  def push_subquery(operator, subquery)
    new_query = {
      'operator' => operator,
      'type' => 'boolean_query',
      'arg1' => subquery.query,
      'arg2' => @query,
    }

    @query = new_query
  end


  def push_term(operator, field, value, type = 'text', negated = false)
    new_query = {
      'operator' => operator,
      'type' => 'boolean_query',
      'arg1' => {
        'field' => field,
        'value' => value,
        'type' => type,
        'negated' => negated,
      },
      'arg2' => @query,
    }

    @query = new_query
  end


  def push_range(operator, field, range, type = 'range', negated = false)
    new_query = {
      'operator' => operator,
      'type' => 'boolean_query',
      'arg1' => {
        'field' => field,
        'from' => range.from,
        'to' => range.to,
        'type' => type,
        'negated' => negated,
      },
      'arg2' => @query,
    }

    @query = new_query
  end

  def build_query(query)
    if query['type'] == 'boolean_query'
      subqueries = [query['arg1'], query['arg2']].compact.map {|subquery|
        build_query(subquery)
      }

      {
        'jsonmodel_type' => 'boolean_query',
        'op' => query['operator'],
        'subqueries' => subqueries
      }
    else
      self.class.as_field_query(query)
    end
  end

  def self.as_field_query(query_data)
    if query_data["type"] == "date"
      query_data.merge({
                         'jsonmodel_type' => 'date_field_query'
                       })
    elsif query_data["type"] == "boolean"
      query_data.merge({
                         'jsonmodel_type' => 'boolean_field_query'
                       })
    elsif query_data["type"] == "range"
      query_data.merge({
                         'jsonmodel_type' => 'range_query'
                       })
    else
      query = query_data.merge({
                                 'jsonmodel_type' => 'field_query'
                               })

      if query_data["type"] == "enum"
        query['literal'] = true
      end

      query
    end
  end

end
