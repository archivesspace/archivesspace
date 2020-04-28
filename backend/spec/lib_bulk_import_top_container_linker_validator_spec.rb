require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/top_container_linker_validator"

#TODO: Have to redo this test because of the recent refactoring

describe "Top Container Linker Validator" do   

  before(:each) do
    @current_user = User.find(:username => "admin")
    @resource = create_resource({ :title => generate(:generic_title), :ead_id => 'hua15019' })
    @tcl = TopContainerLinkerValidator.new("somefile.csv", "text/csv", @current_user, {:rid => @resource[:id], :repo_id => @resource[:repo_id]})
    @res_uri = "/repositories/#{@resource[:repo_id]}/resources/#{@resource[:id]}"
    @ao = ArchivalObject.create_from_json(
          build(:json_archival_object,
              :title => 'A new archival object',
              :ref_id => 'hua15019c00007'),
              :repo_id => $repo_id)
     @tc = create_top_container()         
  end

  def hash_it(obj)
    ASUtils.jsonmodels_to_hashes(obj)
  end
  
  def valid_tc_linking_data
    {"ead_id" => "hua15019", "ref_id"=>"hua15019c00007","instance_type"=>"unspecified", "top_container_indicator"=>"Box 1"}
  end
  
  def invalid_tc_linking_data_ead_id_missing
    {"ref_id"=>"hua15019c00007", "instance_type"=>"unspecified", "top_container_indicator"=>"Box 1"}
  end

    
  def invalid_tc_linking_data_ref_id_missing
    {"ead_id" => "hua15019", "instance_type"=>"unspecified", "top_container_indicator"=>"Box 1"}
  end

  def invalid_tc_linking_data_instance_type_missing
    {"ead_id" => "hua15019", "ref_id"=>"hua15019c00007","top_container_indicator"=>"Box 1"}
  end
  
  def invalid_tc_linking_data_indicator_rec_no_missing
    {"ead_id" => "hua15019", "ref_id"=>"hua15019c00007","instance_type"=>"unspecified"}
  end
  
  def invalid_tc_linking_data_indicator_rec_no_exist
    {"ead_id" => "hua15019", "ref_id"=>"hua15019c00007","instance_type"=>"unspecified", "top_container_indicator"=>"Box 1", "top_container_id" => "12345"}
  end
  
  def invalid_tc_linking_data_barcode_exists
    {"ead_id" => "hua15019", "ref_id"=>"hua15019c00007","instance_type"=>"unspecified", "top_container_indicator"=>"Box 1", "top_container_barcode" => @tc.barcode}
  end

#  it "Checks the validation method with valid input" do
#    retval = @tcl.row_hash = valid_tc_linking_data
#    expect(@tcl.process_row).to_not raise_error
#  end
#  
#  it "Checks the validation method a missing ead_id" do
#    @tcl.row_hash = invalid_tc_linking_data_ead_id_missing
#    expect(@tcl.process_row).to raise_error
#  end
  
#  it "Checks the validation method a missing ref_id" do
#    retval = @tcl.check_row(invalid_tc_linking_data_ref_id_missing)
#    expect(retval).not_to be_empty
#  end  
#  
#  it "Checks the validation method with missing instance type" do
#    retval = @tcl.check_row(invalid_tc_linking_data_instance_type_missing)
#    expect(retval).not_to be_empty
#  end
#  
#  it "Checks the validation method for a missing indicator and TC record number" do
#    retval = @tcl.check_row(invalid_tc_linking_data_indicator_rec_no_missing)
#    expect(retval).not_to be_empty
#  end
#  
#  it "Checks the validation method when both an indicator and TC record number exists" do
#    retval = @tcl.check_row(invalid_tc_linking_data_indicator_rec_no_exist)
#    expect(retval).not_to be_empty
#  end
#
#  it "Checks the validation method for a barcode that already exists in the database" do
#    retval = @tcl.check_row(invalid_tc_linking_data_barcode_exists)
#    expect(retval).not_to be_empty
#  end
#  
#  it "Tests the find_top_container function with various parameters" do
#    tc_obj = find_top_container({:barcode => @tc.barcode})
#    expect(tc_obj["barcode"]).to eq(@tc.barcode)
#  end
    
  it "reads in a CSV file and validates that it initializes properly" do
    tcl_real_file = TopContainerLinkerValidator.new(File.join(File.dirname(__FILE__),'testTopLinkerUpload.csv'), "text/csv", @current_user, {:rid => @resource[:id], :repo_id => @resource[:repo_id]})
    rows = tcl_real_file.initialize_info
    expect(rows).to be_kind_of(Enumerator)
  end
  it "reads in a XLSX file and validates that it initializes properly" do
    tcl_real_file = TopContainerLinkerValidator.new(File.join(File.dirname(__FILE__),'testTopLinkerUpload.xlsx'), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", @current_user, {:rid => @resource[:id], :repo_id => @resource[:repo_id]})
    rows = tcl_real_file.initialize_info
    expect(rows).to be_kind_of(Enumerator)
  end
   
end
