require 'spec_helper'

describe "Record model" do

  it "builds a display string for an untitled record using its parent resource and its date" do
    solr_result = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'solr_response.json')))
    record = Record.new(solr_result)
    expect(record.display_string).to eq "Resource with child inheriting title, bulk: 1900s"
  end

  it "does not show the top container barcode when the top container is not resolved from Solr" do
    solr_result = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'solr_response.json')))
    json = ASUtils.json_parse(solr_result['json'])
    json['instances'] = [{
      'instance_type' => 'mixed_materials',
      'sub_container' => {
        'top_container' => {
          'ref' => '/repositories/2/top_containers/1',
          '_resolved' => {
            'type' => 'box',
            'indicator' => '1',
            'barcode' => '8675309',
            'display_string' => 'Box 1: Series 2 [Barcode: 8675309]'
          }
        },
        'type_2' => 'folder',
        'indicator_2' => '3'
      }
    }]
    solr_result['json'] = json

    record = Record.new(solr_result)
    expect(record.container_summary_for_badge).to eq "Box: 1, Folder: 3"
  end
end
