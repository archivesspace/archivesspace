require 'spec_helper'

describe 'ID Lookup controller' do

  let (:archival_objects) {(0..5).map {|_| create(:json_archival_object, :component_id => SecureRandom.hex)}}
  let (:resources) {(0..5).map {|_| create(:json_resource, :id_0 => SecureRandom.hex)}}
  let (:digital_object_components) {(0..5).map {|_| create(:json_digital_object_component, :component_id => SecureRandom.hex)}}
  let (:top_containers) {(0..5).map {|_| create(:json_top_container, :indicator => _.to_s, :barcode => SecureRandom.hex)}}

  it "lets you find archival objects by ref_id or component_id" do
    ['ref_id', 'component_id'].each do |id_field|
      get "#{$repo}/find_by_id/archival_objects", {"#{id_field}[]" => archival_objects.map {|ao| ao[id_field]}}
      expect(last_response).to be_ok
      ao_lookup = ASUtils.json_parse(last_response.body)

      expect(ao_lookup['archival_objects'].length).to eq(archival_objects.length), "Failed lookup by #{id_field}"
    end
  end

  it "lets you find digital objects by component_id" do
    ['component_id'].each do |id_field|
      get "#{$repo}/find_by_id/digital_object_components", {"#{id_field}[]" => digital_object_components.map {|doc| doc[id_field]}}
      expect(last_response).to be_ok
      doc_lookup = ASUtils.json_parse(last_response.body)

      expect(doc_lookup['digital_object_components'].length).to eq(digital_object_components.length), "Failed lookup by #{id_field}"
    end
  end

  it "can resolve the response it gets back" do
    ao = create(:json_archival_object)
    get "#{$repo}/find_by_id/archival_objects", {
          "ref_id[]" => ao['ref_id'],
          "resolve[]" => "archival_objects"
        }

    expect(last_response).to be_ok
    ao_lookup = ASUtils.json_parse(last_response.body)

    expect(ao_lookup['archival_objects'][0]['_resolved']['title']).to eq(ao['title'])
  end

  it "only returns one resource for a given identifier" do
    resources.each do |resource|
      get "#{$repo}/find_by_id/resources", {"identifier[]" => ["#{resource['id_0'].split}"]}
      expect(last_response).to be_ok
      res_lookup = ASUtils.json_parse(last_response.body)

      expect(res_lookup['resources'].count).to eq(1)
    end
  end

  it "lets you find top containers by indicator or barcode" do
    ['indicator', 'barcode'].each do |id_field|
      get "#{$repo}/find_by_id/top_containers", {"#{id_field}[]" => top_containers.map {|tc| tc[id_field]}}
      expect(last_response).to be_ok
      tc_lookup = ASUtils.json_parse(last_response.body)

      expect(tc_lookup['top_containers'].length).to eq(top_containers.length), "Failed lookup by #{id_field}"
    end
  end

end
