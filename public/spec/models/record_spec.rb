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

  describe "AppConfig[:pui_display_barcodes]" do
    def solr_result_with_top_container(top_container, child_barcode = '12345')
      solr_result = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'solr_response.json')))
      json = ASUtils.json_parse(solr_result['json'])
      json['instances'] = [{
        'instance_type' => 'mixed_materials',
        'sub_container' => {
          'top_container' => {
            'ref' => '/repositories/2/top_containers/1',
            '_resolved' => top_container
          },
          'type_2' => 'folder',
          'indicator_2' => '3',
          'barcode_2' => child_barcode
        }
      }]
      solr_result['json'] = json
      solr_result
    end

    let(:top_container) { { 'type' => 'box', 'indicator' => '1', 'barcode' => '8675309' } }

    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
    end

    context "when false" do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:pui_display_barcodes) { false }
      end

      it "does not show the barcode in container information" do
        record = Record.new(solr_result_with_top_container(top_container))
        expect(record.container_summary_for_badge).to eq "Box: 1, Folder: 3"
        expect(record.container_display).to eq ["Box: 1, Folder: 3 (Mixed Materials)"]
      end

      it "does not show the barcode in the top container display string" do
        container = Container.new({ 'json' => top_container })
        expect(container.display_string).to eq "Box 1"
      end
    end

    context "when true" do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:pui_display_barcodes) { true }
      end

      it "shows the top container and child barcodes in container information" do
        record = Record.new(solr_result_with_top_container(top_container))
        expect(record.container_summary_for_badge).to eq "Box: 1 [Barcode: 8675309], Folder: 3 [Barcode: 12345]"
        expect(record.container_display).to eq ["Box: 1 [Barcode: 8675309], Folder: 3 [Barcode: 12345] (Mixed Materials)"]
      end

      it "does not show the barcode in citations" do
        record = Record.new(solr_result_with_top_container(top_container))
        expect(record.send(:parse_container_display, :citation => true)).to eq ["Box: 1, Folder: 3"]
      end

      it "does not show the barcode in request container information" do
        record = Record.new(solr_result_with_top_container(top_container))
        expect(record.send(:build_request_item_container_info)[:container]).to eq ["Box: 1, Folder: 3 (Mixed Materials)"]
      end

      it "does not show a barcode label when the top container and child have no barcode" do
        record = Record.new(solr_result_with_top_container(top_container.merge('barcode' => nil), nil))
        expect(record.container_summary_for_badge).to eq "Box: 1, Folder: 3"
      end

      it "shows the barcode in the top container display string" do
        container = Container.new({ 'json' => top_container })
        expect(container.display_string).to eq "Box 1 [Barcode: 8675309]"
      end
    end
  end
end
