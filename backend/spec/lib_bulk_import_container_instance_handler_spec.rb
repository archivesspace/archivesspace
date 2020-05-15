require "spec_helper"
require_relative "../app/lib/bulk_import/container_instance_handler"
require_relative "../app/lib/bulk_import/handler"

describe "Container Instance Handler" do
  before(:each) do
    @report = BulkImportReport.new
    @report.new_row(1)
    current_user = User.find(:username => "admin")
    @handlr = Handler.new(current_user)
    @cih = ContainerInstanceHandler.new(current_user)
    @resource = create_resource({ :title => generate(:generic_title) })
    @res_uri = "/repositories/#{@resource[:repo_id]}/resources/#{@resource[:id]}"
  end

  def current_row
    @report.instance_variable_get(:@current_row)
  end

  def hash_it(obj)
    ASUtils.jsonmodels_to_hashes(obj)
  end

  def teststruct
    { :type => "box", :indicator => "1", :barcode => "2342" }
  end

  def create_top
    top_container = teststruct
    key = @cih.key_for(top_container, @res_uri)
    tc = JSONModel(:top_container).new._always_valid!
    tc.type = top_container[:type]
    tc.indicator = top_container[:indicator]
    tc.barcode = top_container[:barcode] if top_container[:barcode]
    tc.repository = { "ref" => @res_uri.split("/")[0..2].join("/") }
    tc = @cih.save(tc, TopContainer)
    @cih.instance_variable_get(:@top_containers)[key] = tc
  end

  it "builds a container instance struct" do
    results = @cih.build("Box", "1", "2342")
    expect(results).to eq(teststruct)
  end

  it "rejects a bad container type" do
    expect {
      results = @cih.build("Boxes", "1", "2342")
    }.to raise_error("NOT FOUND: 'Boxes' not found in list container_type")
  end
  it "creates an instance, first by creating it in the database" do
    create_top
    results = @cih.get_or_create("Box", "1", "2342", @res_uri, @report)
    hsh = hash_it(results)
    expect(hsh["long_display_string"]).to eq("Box 1 [Barcode: 2342]")
    instances = @cih.create_container_instance("Audio", "Box", "1", "2342", @res_uri, @report)
    expect(instances.instance_type).to eq("audio")
  end
  it "tries to create an instance with an invalid instance type" do
    create_top
    expect {
      instances = @cih.create_container_instance("Phonograph", "Box", "1", "2342", @res_uri, @report)
    }.to raise_error("NOT FOUND: 'Phonograph' not found in list instance_instance_type")
  end
end
