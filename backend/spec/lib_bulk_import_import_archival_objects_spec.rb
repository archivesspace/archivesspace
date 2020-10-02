# test ingest
require "spec_helper"
require_relative "../app/lib/bulk_import/import_archival_objects.rb"

describe "Import Archival Objects" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  before(:each) do
    @current_user = User.find(:username => "admin")
    # create the resource
    resource = JSONModel(:resource).from_hash("title" => "a resource",
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

    id = resource.save
    @resource = Resource.get_or_die(id)
  end
  it "reads in excel spreadsheet at the resource level" do
    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => "bulk_import_VFIRST01_test01.xlsx",
             :filepath => BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.xlsx",
             :load_type => "archival_object",
             :ref_id => "",
             :aoid => "",
             :position => "" }
    importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
    report = importer.run
    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(2)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_display).to eq("The first series, bulk: 2010 - 2020, 2020")
    expect(report.rows[1].archival_object_display).to eq("A subseries, 2010 - 2011")
    tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id).to_hash
    children = tree["children"]
    #    aos = []
    children.each_with_index do |child, index|
      expect(child["record_uri"]).to eq(report.rows[index].archival_object_id)
      #      ao = JSONModel(:archival_object).find_by_uri(child["record_uri"]).to_hash
      #      aos << ao
    end
  end
  it "reads in CSV spreadsheet at the resource level" do
    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => "bulk_import_VFIRST01_test01.csv",
             :filepath => BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.csv",
             :load_type => "archival_object",
             :ref_id => "",
             :aoid => "",
             :position => "" }
    importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
    report = importer.run
    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(2)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_display).to eq("The first series, bulk: 2010 - 2020, 2020")
    expect(report.rows[1].archival_object_display).to eq("A subseries, 2010 - 2011")
    tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id).to_hash
    children = tree["children"]
    #    aos = []
    children.each_with_index do |child, index|
      expect(child["record_uri"]).to eq(report.rows[index].archival_object_id)
      #      ao = JSONModel(:archival_object).find_by_uri(child["record_uri"]).to_hash
      #      aos << ao
    end
  end
end
