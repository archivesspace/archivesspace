require 'spec_helper'

describe "Record model" do

  it "builds a display string for an untitled record using its parent's title" do
    solr_result = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'solr_response.json')))
    record = Record.new(solr_result)
    expect(record.display_string).to eq "From the item: Resource with child inheriting title"
  end
end
