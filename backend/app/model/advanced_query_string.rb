class AdvancedQueryString
  def initialize(query)
    @query = query
  end

  def to_solr_s
    return "(*:* NOT #{field}:*)" if empty_search?
    
    "#{prefix}#{field}:#{value}"
  end

  private

  def prefix
    @query['negated'] ? "-" : ""
  end

  def field
    AdvancedSearch.solr_field_for(@query['field'])
  end

  def value
    if @query["jsonmodel_type"] == "date_field_query"
      if @query["comparator"] == "lesser_than"
        "[* TO #{@query["value"]}T00:00:00Z-1MILLISECOND]"
      elsif @query["comparator"] == "greater_than"
        "[#{@query["value"]}T00:00:00Z+1DAY TO *]"
      else # @query["comparator"] == "equal"
        "[#{@query["value"]}T00:00:00Z TO #{@query["value"]}T00:00:00Z+1DAY-1MILLISECOND]"
      end
    elsif @query["jsonmodel_type"] == "field_query" && @query["literal"]
      "(\"#{solr_escape(@query['value'])}\")"
    else
      "(#{@query['value']})"
    end
  end

  def empty_search?
    if @query["jsonmodel_type"] == "date_field_query"
      @query["comparator"] == "empty"
    elsif @query["jsonmodel_type"] == "boolean_field_query"
      false
    elsif @query["jsonmodel_type"] == "field_query"
      @query["comparator"] == "empty"  
    else
      raise "Unknown field query type: #{@query["jsonmodel_type"]}" 
    end
  end


  SOLR_CHARS = '+-&|!(){}[]^"~*?:\\/'

  def solr_escape(s)
    pattern = Regexp.quote(SOLR_CHARS)
    s.gsub(/([#{pattern}])/, '\\\\\1')
  end
end