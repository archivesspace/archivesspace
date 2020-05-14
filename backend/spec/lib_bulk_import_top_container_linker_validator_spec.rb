require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/top_container_linker_validator"

describe "Top Container Linker Validator" do   

  before(:each) do
    @current_user = User.find(:username => "admin")
    @resource = create_resource({ :title => generate(:generic_title), :ead_id => 'hua15019' })
    @tcl = TopContainerLinkerValidator.new("somefile.csv", "text/csv", @current_user, {:rid => @resource[:id], :repo_id => @resource[:repo_id]})
    #Need this to make sure the checks are valid
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

  it "Checks the validation method with valid input" do
    expect{@tcl.process_row(valid_tc_linking_data)}.to_not raise_error
  end
  
  it "Checks the validation method a missing ead_id" do
    expect{@tcl.process_row(invalid_tc_linking_data_ead_id_missing)}.to raise_error(BulkImportException)
  end
  
  it "Checks the validation method a missing ref_id" do
    expect{@tcl.process_row(invalid_tc_linking_data_ref_id_missing)}.to raise_error(BulkImportException)
  end  
  
  it "Checks the validation method with missing instance type" do
    expect{@tcl.process_row(invalid_tc_linking_data_instance_type_missing)}.to raise_error(BulkImportException)
  end
  
  it "Checks the validation method for a missing indicator and TC record number" do
    expect{@tcl.process_row(invalid_tc_linking_data_indicator_rec_no_missing)}.to raise_error(BulkImportException)
  end
  
  it "Checks the validation method when both an indicator and TC record number exists" do
    expect{@tcl.process_row(invalid_tc_linking_data_indicator_rec_no_exist)}.to raise_error(BulkImportException)
  end

  it "Checks the validation method for a barcode that already exists in the database" do
    expect{@tcl.process_row(invalid_tc_linking_data_barcode_exists)}.to raise_error(BulkImportException)
  end
 
   
end
