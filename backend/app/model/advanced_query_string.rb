require 'time'

class AdvancedQueryString
  def initialize(query, use_literal)
    @query = query
    @use_literal = use_literal
  end

  def to_solr_s
    return empty_solr_s if empty_search?

    solr_field = AdvancedSearch.solr_field_for(@query.fetch('field'))
    record_type_limit = AdvancedSearch.record_type_limit(@query.fetch('field'))

    query = if solr_field.respond_to?(:to_solr_s)
              "#{prefix}(#{solr_field.to_solr_s(@query)})"
            else
              "#{prefix}#{field}:#{value}"
            end

    if record_type_limit
      query = "(%s) AND types:(%s)" % [
        query,
        record_type_limit.join(' OR ')
      ]
    end

    query
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
      record_type_limit = AdvancedSearch.record_type_limit(@query.fetch('field'))

      if record_type_limit
        "(types:(%s) NOT %s:*)" % [record_type_limit.join(' OR '), field]
      else
        "(*:* NOT #{field}:*)"
      end
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
      base_time = Time.parse(@query["value"]).utc.iso8601

      if @query["comparator"] == "lesser_than"
        "[* TO #{base_time}-1MILLISECOND]"
      elsif @query["comparator"] == "greater_than"
        "[#{base_time}+1DAY TO *]"
      else # @query["comparator"] == "equal"
        "[#{base_time} TO #{base_time}+1DAY-1MILLISECOND]"
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
