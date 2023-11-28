require 'spec_helper'

describe "AdvancedQueryString" do

  it "can support day precision with greater-than comparator" do
    query = {"field": "create_time", "value": "1911-03-01", "comparator": "greater_than", "jsonmodel_type": "date_field_query", "precision": "day", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-03-01T\d{2}:00:00Z\+1DAY TO \*\]/
  end

  it "can support day precision with lesser-than comparator" do
    query = {"field": "create_time", "value": "1911-03-01", "comparator": "lesser_than", "jsonmodel_type": "date_field_query", "precision": "day", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[\* TO 1911-03-01T\d{2}:00:00Z-1MILLISECOND\]/
  end

  it "can support day precision with equal comparator" do
    query = {"field": "create_time", "value": "1911-03-01", "comparator": "equal", "jsonmodel_type": "date_field_query", "precision": "day", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-03-01T\d{2}:00:00Z TO 1911-03-01T\d{2}:00:00Z\+1DAY-1MILLISECOND\]/
  end

  it "can support month precision with greater-than comparator" do
    query = {"field": "create_time", "value": "1911-03", "comparator": "greater_than", "jsonmodel_type": "date_field_query", "precision": "month", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-03-01T\d{2}:00:00Z\+1MONTH TO \*\]/
  end

  it "can support month precision with lesser-than comparator" do
    query = {"field": "create_time", "value": "1911-03", "comparator": "lesser_than", "jsonmodel_type": "date_field_query", "precision": "month", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[\* TO 1911-03-01T\d{2}:00:00Z-1MILLISECOND\]/
  end

  it "can support month precision with equal comparator" do
    query = {"field": "create_time", "value": "1911-03", "comparator": "equal", "jsonmodel_type": "date_field_query", "precision": "month", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-03-01T\d{2}:00:00Z TO 1911-03-01T\d{2}:00:00Z\+1MONTH-1MILLISECOND\]/
  end

  it "can support year precision with greater-than comparator" do
    query = {"field": "create_time", "value": "1911", "comparator": "greater_than", "jsonmodel_type": "date_field_query", "precision": "year", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-01-01T\d{2}:00:00Z\+1YEAR TO \*\]/
  end

  it "can support year precision with lesser-than comparator" do
    query = {"field": "create_time", "value": "1911", "comparator": "lesser_than", "jsonmodel_type": "date_field_query", "precision": "year", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[\* TO 1911-01-01T\d{2}:00:00Z-1MILLISECOND\]/
  end

  it "can support year precision with equal comparator" do
    query = {"field": "create_time", "value": "1911", "comparator": "equal", "jsonmodel_type": "date_field_query", "precision": "year", "negated": false}
    advancedQueryString = AdvancedQueryString.new(query)
    expect(advancedQueryString.to_solr_s).to match /create_time:\[1911-01-01T\d{2}:00:00Z TO 1911-01-01T\d{2}:00:00Z\+1YEAR-1MILLISECOND\]/
  end
end
