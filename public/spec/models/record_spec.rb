require 'spec_helper'

describe "Record model" do

  it "builds a display string for an untitled record using its parent resource and its date" do
    solr_result = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'solr_response.json')))
    record = Record.new(solr_result)
    expect(record.display_string).to eq "Resource with child inheriting title, bulk: 1900s"
  end
end
