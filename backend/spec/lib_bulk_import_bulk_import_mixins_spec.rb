require "spec_helper"
require_relative "../app/lib/bulk_import/bulk_import_mixins.rb"
include BulkImportMixins

describe "Bulk Import Mixins" do
  before(:each) do
    @current_user = User.find(:username => "admin")
    # create the resource
    @resource_json = JSONModel(:resource).from_hash("title" => "a resource",
                                                    "dates" => [{
                                                      "date_type" => "single",
                                                      "label" => "creation",
                                                      "expression" => "1901",
                                                    }],
                                                    "id_0" => "abc123",
                                                    "level" => "collection",
                                                    "lang_materials" => [{
                                                      "language_and_script" => {
                                                        "language" => "eng",
                                                        "script" => "Latn",
                                                      },
                                                    }],
                                                    "finding_aid_language" => "eng",
                                                    "finding_aid_script" => "Latn",
                                                    "ead_id" => "VFIRST01",
                                                    "extents" => [{
                                                      "portion" => "whole",
                                                      "number" => "5 or so",
                                                      "extent_type" => "reels",
                                                    }])

    id = @resource_json.save
    @resource = Resource.get_or_die(id)
    # create another resource
    @no_ead_json = JSONModel(:resource).from_hash("title" => "another resource",
                                                  "dates" => [{
                                                    "date_type" => "single",
                                                    "label" => "creation",
                                                    "expression" => "1901",
                                                  }],
                                                  "id_0" => "abc456",
                                                  "level" => "collection",
                                                  "lang_materials" => [{
                                                    "language_and_script" => {
                                                      "language" => "eng",
                                                      "script" => "Latn",
                                                    },
                                                  }],
                                                  "finding_aid_language" => "eng",
                                                  "finding_aid_script" => "Latn",
                                                  "extents" => [{
                                                    "portion" => "whole",
                                                    "number" => "5 or so",
                                                    "extent_type" => "reels",
                                                  }])

    id = @no_ead_json.save
    @resource_no_ead = Resource.get_or_die(id)

    @tc = create_top_container()
    @sc = create_sub_container()
    
    opts = {:title => 'A new archival object', :resource => {:ref => @resource.uri}, :instances => [build(:json_instance,
      :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]}
    @ao = ArchivalObject.create_from_json(
            build(:json_archival_object,
                opts),
                :repo_id => $repo_id)
  end

  it "handles missing EAD ID and URI" do
    match = expect {
      resource_match(@resource_json, nil, nil)
    }.to raise_error("This row is missing BOTH an EAD ID and URI")
  end

  it "matches resource by uri" do
    match = resource_match(@no_ead_json, nil, @no_ead_json["uri"])
    expect(match).to be(true)
  end

  it "matches resource by ead id" do
    match = resource_match(@resource_json, "VFIRST01", nil)
    expect(match).to be(true)
  end
  it "fails to match resource by uri" do
    expect {
      resource_match(@resource_json, nil, @no_ead_json["uri"])
    }.to raise_error(BulkImportException)
  end
  it "fails to match resource by ead id" do
    expect {
      resource_match(@resource_json, "VFIRST02", nil)
    }.to raise_error(BulkImportException, /Form\'s EAD ID/)
  end
  it "fails because the resource is missing the ead id" do
    expect {
      resource_match(@no_ead_json, "VFIRST01", nil)
    }.to raise_error(BulkImportException, "This form's Resource is missing an EAD ID")
  end

  it "retrieves an archival object by REF ID" do
    ao = create(:json_archival_object, { :title => "archival object: Hi There" })
    ao.resource = { :ref => @resource.uri }
    ao.save
    new_ao = archival_object_from_ref_or_uri(ao.ref_id, nil)
    new_ao = new_ao[:ao]
    expect(new_ao.uri).to eq(ao.uri)
  end
  it "retrieves an archival object by uri" do
    ao = create(:json_archival_object, { :title => "archival object: Hi There" })
    ao.resource = { :ref => @resource.uri }
    ao.save
    new_ao = archival_object_from_ref_or_uri(nil, ao.uri)
    new_ao = new_ao[:ao]
    expect(new_ao.title).to eq(ao.title)
  end
  it "fails to retrieve an archival object by REFID" do
    new_ao = archival_object_from_ref_or_uri("HI_01", nil)
    expect(new_ao[:ao]).to eq(nil)
  end
  it "fails to retrieve an archival object by uri" do
    new_ao = archival_object_from_ref_or_uri(nil, "/repositories/5/archival_objects/4")
    expect(new_ao[:ao]).to eq(nil)
  end
  it "fails to retrieve an archival object due to no URI or REF_ID" do
    new_ao = archival_object_from_ref_or_uri(nil, nil)
    expect(new_ao[:ao]).to eq(nil)
    expect(new_ao[:errs]).to eq("Neither an archival object URI nor a REF ID was provided")
  end
  
  it "Tests the find_top_container function with a barcode parameter" do
    tc_obj = find_top_container({:barcode => @tc.barcode})
    expect(tc_obj["barcode"]).to eq(@tc.barcode)
  end
  
  it "Tests the sub_container_from_barcode function returns the expected result" do
    sc_obj = sub_container_from_barcode(@sc.barcode_2)
    expect(sc_obj["barcode_2"]).to eq(@sc.barcode_2)
  end
  
  it "That the count of the indicator and container type is > 0" do
    ind_type_exist = indicator_and_type_exist_for_resource?(@resource.ead_id, @tc.indicator, @tc.type_id)
    expect(ind_type_exist).to be true
  end

  after(:each) do
    @no_ead_json.delete
    @resource_json.delete
  end
end
