# test ingest
require "spec_helper"
require_relative "../app/lib/bulk_import/import_archival_objects.rb"

describe "Import Archival Objects" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "templates")
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

  # we don't want to test fixtures with different keys than the real templates!
  it "keeps the example fixtures up to date with the templates" do
    xlsx_fixture = BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.xlsx"
    xlsx_template = TEMPLATES_DIR + "/bulk_import_template.xlsx"
    xlsx_fixture = RubyXL::Parser.parse(xlsx_fixture)
    xlsx_template = RubyXL::Parser.parse(xlsx_template)

    fixture_keys = xlsx_fixture.worksheets[0][3].cells.map { |c| c.value }
    template_keys = xlsx_template.worksheets[0][3].cells.map { |c| c.value }
    expect(template_keys - fixture_keys).to be_empty
    expect(fixture_keys - template_keys).to be_empty

    csv_fixture = BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.csv"
    csv_template = TEMPLATES_DIR + "/bulk_import_template.csv"
    csv_fixture = CSV.read(csv_fixture)
    csv_template = CSV.read(csv_template)

    fixture_keys = csv_fixture.to_a.first
    template_keys = csv_template.to_a.first
    expect(template_keys - fixture_keys).to be_empty
    expect(fixture_keys - template_keys).to be_empty
  end

  it "doesn't have any duplicate keys in the template" do
    xlsx_template = TEMPLATES_DIR + "/bulk_import_template.xlsx"
    xlsx_template = RubyXL::Parser.parse(xlsx_template)

    template_keys = xlsx_template.worksheets[0][3].cells.map { |c| c.value }
    expect(template_keys.size).to eq template_keys.uniq.size
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

    tree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/root")
    expect(tree["precomputed_waypoints"][""]["0"][0]["uri"]).to eq(report.rows[0].archival_object_id)
    subtree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/node", {node_uri: report.rows[0].archival_object_id})
    expect(subtree["precomputed_waypoints"][report.rows[0].archival_object_id]["0"][0]["uri"]).to eq(report.rows[1].archival_object_id)
    dig_obj = JSONModel(:digital_object).find(
      JSONModel(:digital_object).id_for(
        JSONModel::HTTP.get_json(report.rows[0].archival_object_id)["instances"][0]["digital_object"]["ref"]
      )
    )
    expect(dig_obj.publish).to be false
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
    tree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/root")
    expect(tree["precomputed_waypoints"][""]["0"][0]["uri"]).to eq(report.rows[0].archival_object_id)
    subtree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/node", {node_uri: report.rows[0].archival_object_id})
    expect(subtree["precomputed_waypoints"][report.rows[0].archival_object_id]["0"][0]["uri"]).to eq(report.rows[1].archival_object_id)
  end
end
