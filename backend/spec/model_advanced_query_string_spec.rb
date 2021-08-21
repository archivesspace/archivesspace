require 'spec_helper'

describe "AdvancedQueryString" do

  it "can support date granularity of day, month, or year" do
    query = {"field": "create_time", "value": "1911-03-01", "comparator": "greater_than", "jsonmodel_type": "date_field_query", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query, false)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-03-01T\d{2}:00:00Z\+1DAY TO \*\]/

    query = {"field": "create_time", "value": "1911-03", "comparator": "greater_than", "jsonmodel_type": "date_field_query", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query, false)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-03-01T\d{2}:00:00Z\+1DAY TO \*\]/

    query = {"field": "create_time", "value": "1911", "comparator": "greater_than", "jsonmodel_type": "date_field_query", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query, false)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-01-01T\d{2}:00:00Z\+1DAY TO \*\]/
  end
end
