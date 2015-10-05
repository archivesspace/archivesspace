require 'spec_helper'

describe 'ID Lookup controller' do

  let (:archival_objects) {(0..5).map {|_| create(:json_archival_object, :component_id => SecureRandom.hex)}}
  let (:digital_object_components) {(0..5).map {|_| create(:json_digital_object_component, :component_id => SecureRandom.hex)}}

  it "lets you find archival objects by ref_id or component_id" do
    ['ref_id', 'component_id'].each do |id_field|
      get "#{$repo}/find_by_id/archival_objects", {"#{id_field}[]" => archival_objects.map {|ao| ao[id_field]}}
      last_response.should be_ok
      ao_lookup = ASUtils.json_parse(last_response.body)

      ao_lookup['archival_objects'].length.should eq(archival_objects.length), "Failed lookup by #{id_field}"
    end
  end

  it "lets you find digital objects by component_id" do
    ['component_id'].each do |id_field|
      get "#{$repo}/find_by_id/digital_object_components", {"#{id_field}[]" => digital_object_components.map {|doc| doc[id_field]}}
      last_response.should be_ok
      doc_lookup = ASUtils.json_parse(last_response.body)

      doc_lookup['digital_object_components'].length.should eq(digital_object_components.length), "Failed lookup by #{id_field}"
    end
  end

  it "can resolve the response it gets back" do
    ao = create(:json_archival_object)
    get "#{$repo}/find_by_id/archival_objects", {
          "ref_id[]" => ao['ref_id'],
          "resolve[]" => "archival_objects"
        }

    last_response.should be_ok
    ao_lookup = ASUtils.json_parse(last_response.body)

    ao_lookup['archival_objects'][0]['_resolved']['title'].should eq(ao['title'])
  end

end
