require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/top_container_linker_validator"



describe "Top Container Linker Validator" do   

  before(:each) do
    current_user = User.find(:username => "admin")
    @resource = create_resource({ :title => generate(:generic_title), :ead_id => 'hua15019' })
    @tcl = TopContainerLinkerValidator.new("somefile.csv", "text/csv", {:rid => @resource[:id], :repo_id => @resource[:repo_id]}, current_user)
    @res_uri = "/repositories/#{@resource[:repo_id]}/resources/#{@resource[:id]}"
    @ao = ArchivalObject.create_from_json(
          build(:json_archival_object,
              :title => 'A new archival object',
              :ref_id => 'hua15019c00007'),
              :repo_id => $repo_id)
  end

  def hash_it(obj)
    ASUtils.jsonmodels_to_hashes(obj)
  end
  
  def valid_tc_linking_data
    {"EADID" => "hua15019", "Ref ID"=>"hua15019c00007","Instance Type"=>"unspecified", "Top Container Indicator"=>"Box 1"}
  end
  
  def invalid_tc_linking_data_ead_id_missing
    {"Ref ID"=>"hua15019c00007", "Instance Type"=>"unspecified", "Top Container Indicator"=>"Box 1"}
  end

    
  def invalid_tc_linking_data_ref_id_missing
    {"EADID" => "hua15019", "Instance Type"=>"unspecified", "Top Container Indicator"=>"Box 1"}
  end

  def invalid_tc_linking_data_instance_type_missing
    {"EADID" => "hua15019", "Ref ID"=>"hua15019c00007","Top Container Indicator"=>"Box 1"}
  end
  
  def invalid_tc_linking_data_indicator_rec_no_missing
    {"EADID" => "hua15019", "Ref ID"=>"hua15019c00007","Instance Type"=>"unspecified"}
  end
  
  def invalid_tc_linking_data_indicator_rec_no_exist
    {"EADID" => "hua15019", "Ref ID"=>"hua15019c00007","Instance Type"=>"unspecified", "Top Container Indicator"=>"Box 1", "Top Container Record No." => "12345"}
  end

  it "Checks the validation method with valid input" do
    retval = @tcl.check_row(valid_tc_linking_data)
    expect(retval).to be_empty
  end
  
  it "Checks the validation method a missing ead_id" do
    retval = @tcl.check_row(invalid_tc_linking_data_ead_id_missing)
    expect(retval).not_to be_empty
  end
  
  it "Checks the validation method a missing ref_id" do
    retval = @tcl.check_row(invalid_tc_linking_data_ref_id_missing)
    expect(retval).not_to be_empty
  end  
  
  it "Checks the validation method with missing instance type" do
    retval = @tcl.check_row(invalid_tc_linking_data_instance_type_missing)
    expect(retval).not_to be_empty
  end
  
  it "Checks the validation method with missing indicator and TC record number" do
    retval = @tcl.check_row(invalid_tc_linking_data_indicator_rec_no_missing)
    expect(retval).not_to be_empty
  end
  
  it "Checks the validation method with both an indicator and TC record number" do
    retval = @tcl.check_row(invalid_tc_linking_data_indicator_rec_no_exist)
    expect(retval).not_to be_empty
  end
  
#  it "reads in a CSV file and validates that it can be parsed" do
#    table = CSV.read(File.join(File.dirname(__FILE__),'testTopLinkerUpload.csv'), headers: true)
#    rows = table.enum_for(:each)
#    row = rows.next
#    puts row.to_h
#  end
  
   
end
