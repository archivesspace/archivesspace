require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/bulk_import_mixins.rb"

describe "Bulk Mixins" do
  before(:each) do
    create(:repo)
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
  end

  it "handles missing EAD ID and URI" do
    match = expect {
      resource_match(@resource_json, nil, nil)
    }.to raise_error("This row is missing BOTH and EAD ID and URI")
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
  after(:each) do
    @no_ead_json.delete
    @resource_json.delete
  end
end
