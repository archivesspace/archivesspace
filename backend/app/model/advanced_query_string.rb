require 'time'

class AdvancedQueryString
  def initialize(query, use_literal)
    @query = query.transform_keys { |k| k.to_s }
    @use_literal = use_literal
  end

  def to_solr_s
    return empty_solr_s if empty_search?

    "#{prefix}#{field}:#{value}"
  end

  private

  def use_literal?
    @use_literal
  end

  def empty_solr_s
    if negated?
      if date?
        "#{field}:[* TO *]"
      else
        "#{field}:['' TO *]"
      end
    else
      "(*:* NOT #{field}:*)"
    end
  end

  def prefix
    negated? ? "-" : ""
  end

  def field
    AdvancedSearch.solr_field_for(@query['field'])
  end

  def value
    if date?
      query_comparator = @query["comparator"]
      query_precision = @query["precision"]
      query_date = JSONModel::Validations.normalise_date(@query["value"])
      base_time = Time.parse(query_date).utc.iso8601

      case query_precision
      when "day"
        case query_comparator
        when "greater_than" then "[#{base_time}+1DAY TO *]"
        when "lesser_than" then "[* TO #{base_time}-1MILLISECOND]"
        when "equal" then "[#{base_time} TO #{base_time}+1DAY-1MILLISECOND]"
        end
      when "month"
        case query_comparator
        when "greater_than" then "[#{base_time}+1MONTH TO *]"
        when "lesser_than" then "[* TO #{base_time}-1MILLISECOND]"
        when "equal" then "[#{base_time} TO #{base_time}+1MONTH-1MILLISECOND]"
        end
      when "year"
        case query_comparator
        when "greater_than" then "[#{base_time}+1YEAR TO *]"
        when "lesser_than" then "[* TO #{base_time}-1MILLISECOND]"
        when "equal" then "[#{base_time} TO #{base_time}+1YEAR-1MILLISECOND]"
        end
      end
    elsif @query["jsonmodel_type"] == "range_query"
      "[#{@query["from"] || '*'} TO #{@query["to"] || '*'}]"
    elsif @query["jsonmodel_type"] == "field_query" && (use_literal? || @query["literal"])
      "(\"#{solr_escape(@query['value'])}\")"
    else
      "(#{replace_reserved_chars(@query['value'].to_s)})"
    end
  end

  def empty_search?
    if @query["jsonmodel_type"] == "date_field_query"
      @query["comparator"] == "empty"
    elsif @query["jsonmodel_type"] == "boolean_field_query"
      false
    elsif @query["jsonmodel_type"] == "field_query"
      @query["comparator"] == "empty"
    elsif @query["jsonmodel_type"] == "range_query"
      false
    else
      raise "Unknown field query type: #{@query["jsonmodel_type"]}"
    end
  end

  def negated?
    @query['negated']
  end

  def date?
    @query["jsonmodel_type"] == "date_field_query"
  end


  SOLR_CHARS = '+-&|!(){}[]^"~*?:\\/'
  RESERVED_CHARS = ':'

  def solr_escape(s)
    pattern = Regexp.quote(SOLR_CHARS)
    s.gsub(/([#{pattern}])/, '\\\\\1')
  end

  def replace_reserved_chars(s)
    pattern = Regexp.quote(RESERVED_CHARS)
    s.gsub(/([#{pattern}])/, ' ')
  end
end
