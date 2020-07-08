require "spec_helper"
require_relative "../app/lib/bulk_import/top_container_linker"


describe "Top Container Linker" do   
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  before(:each) do
    @current_user = User.find(:username => "admin")
    
    @resource = create_resource({ :title => generate(:generic_title), :ead_id => 'hua15019' })
    @tc = create_top_container({:indicator => "Box 1", :type => "box", :barcode => "121212"})
    @loc = create_location()
    @cp = create_container_profile()
            
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00007', 
      :instances => [build(:json_instance,
              :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00008', :instances => [build(:json_instance,
      :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00009', :instances => [build(:json_instance,
      :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00010', :instances => [build(:json_instance,
      :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00011', :instances => [build(:json_instance,
      :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
    
    @resource2 = create_resource({ :title => generate(:generic_title), :ead_id => 'hua12345' })
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource2.uri}, :ref_id => 'hua12345c00007'})
     
    @resource3 = create_resource({ :title => generate(:generic_title), :ead_id => 'hua6789' })
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource3.uri}, :ref_id => 'hua6789c00007'})
    
    create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource3.uri}, :ref_id => 'hua6789c00008'})
       
   end
    
   def row_1_data
    {"ead_id" => "hua12345", 
      "ref_id"=>"hua12345c00007",
      "instance_type"=>"books", 
      "top_container_indicator"=>"Box 1", 
      "top_container_type"=>"Box", 
      "top_container_barcode" => nil,
      "child_type" => nil,
      "child_indicator" => nil,
      "child_barcode" => nil,
      "location_id" => nil,
      "container_profile_id" => nil}
   end
   def row_2_data
    {"ead_id" => "hua6789", 
      "ref_id"=>"hua6789c00007",
      "instance_type"=>"books", 
      "top_container_indicator"=>"Box 2", 
      "top_container_type"=>"Box", 
      "top_container_barcode" => nil,
      "child_type" => nil,
      "child_indicator" => nil,
      "child_barcode" => nil,
      "location_id" => nil,
      "container_profile_id" => nil}
   end
   def row_3_data
    {"ead_id" => "hua6789", 
      "ref_id"=>"hua6789c00008",
      "instance_type"=>"books", 
      "top_container_indicator"=>"Box 2", 
      "top_container_type"=>"Box", 
      "top_container_barcode" => nil,
      "child_type" => nil,
      "child_indicator" => nil,
      "child_barcode" => nil,
      "location_id" => nil,
      "container_profile_id" => nil}
   end
   def complete_data_with_type_ind
    {"ead_id" => "hua6789", 
      "ref_id"=>"hua6789c00008",
      "instance_type"=>"books", 
      "top_container_indicator"=>"Box 2", 
      "top_container_type"=>"Box", 
      "top_container_barcode" => "bc1",
      "child_type" => "folder",
      "child_indicator" => "Child2",
      "child_barcode" => "child_bc",
      "location_id" => @loc.id.to_s,
      "container_profile_id" => @cp.id.to_s}
   end

   def complete_data_with_container_id
    {"ead_id" => "hua6789", 
      "ref_id"=>"hua6789c00008",
      "instance_type"=>"books", 
      "top_container_id"=>@tc.id.to_s, 
      "child_type" => "folder",
      "child_indicator" => "Child2",
      "child_barcode" => "child_bc"}
   end
   
    it "reads in csv spreadsheet and runs with no errors" do
      opts = { :repo_id => @resource[:repo_id],
               :rid => @resource[:id],
               :filename => "testTopLinkerUpload.csv",
               :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv",
               :ref_id => "",
               :aoid => "",
               :position => "" }
      tcl = TopContainerLinker.new(opts[:filepath], "text/csv", @current_user, opts)
      report = tcl.run
      expect(report.terminal_error).to eq(nil)
      expect(report.row_count).to eq(5)
      expect(report.rows[0].errors).to eq([])
      expect(report.rows[1].errors).to eq([])
      expect(report.rows[2].errors).to eq([])
      expect(report.rows[3].errors).to eq([])
      expect(report.rows[4].errors).to eq([])
  end
  
  

  it "reads in excel spreadsheet and runs with no errors" do
      opts = { :repo_id => @resource[:repo_id],
               :rid => @resource[:id],
               :filename => "testTopLinkerUpload.xlsx",
               :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.xlsx",
               :ref_id => "",
               :aoid => "",
               :position => "" }
      tcl = TopContainerLinker.new(opts[:filepath], "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", @current_user, opts)
      report = tcl.run
      expect(report.terminal_error).to eq(nil)
      expect(report.row_count).to eq(5)
      expect(report.rows[0].errors).to eq([])
      expect(report.rows[1].errors).to eq([])
      expect(report.rows[2].errors).to eq([])
      expect(report.rows[3].errors).to eq([])
      expect(report.rows[4].errors).to eq([])
  end
  
  it "validates that adding the same type-indicator to two separate AOs with different resources will create two top containers" do
    opts1 = { :repo_id => @resource2[:repo_id],
                   :rid => @resource2[:id],
                   :filename => "testTopLinkerUpload.csv",
                   :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv"}

    tcl1 = TopContainerLinker.new(opts1[:filepath], "text/csv", @current_user, opts1)
    ao =tcl1.process_row(row_1_data)
    
    expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).not_to eq(@tc.uri)   
  end
  
  it "validates that adding the same type-indicator to two separate AOs with the same resource will create one top container" do
    opts1 = { :repo_id => @resource3[:repo_id],
                   :rid => @resource3[:id],
                   :filename => "testTopLinkerUpload.csv",
                   :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv"}
    tcl1 = TopContainerLinker.new(opts1[:filepath], "text/csv", @current_user, opts1)
    ao =tcl1.process_row(row_2_data)
    ao2 =tcl1.process_row(row_3_data)
    
    expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).to eq(ao2["instances"][0]["sub_container"]["top_container"]["ref"])   
  end
  
  it "validates that adding all possible data with a type/indicator creates an links the TC" do
    opts1 = { :repo_id => @resource3[:repo_id],
                   :rid => @resource3[:id],
                   :filename => "testTopLinkerUpload.csv",
                   :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv"}
    tcl1 = TopContainerLinker.new(opts1[:filepath], "text/csv", @current_user, opts1)
    ao =tcl1.process_row(complete_data_with_type_ind)
    expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).not_to be_nil   
    expect(ao["instances"][0]["instance_type"]).to eq("books")   
    expect(ao["instances"][0]["sub_container"]["type_2"]).to eq("folder")   
    expect(ao["instances"][0]["sub_container"]["indicator_2"]).to eq("Child2")  
    expect(ao["instances"][0]["sub_container"]["barcode_2"]).to eq("child_bc")    
    tc_obj = TopContainer.to_jsonmodel(ao["instances"][0]["sub_container"]["top_container"]["ref"].split("/")[4].to_i)
    expect(tc_obj["container_locations"][0]["location_id"]).to eq(@loc.id)
    expect(tc_obj["container_profile"]["container_profile_id"]).to eq(@cp.id)
  end
  
  it "validates that adding all possible data with a container_id creates an links the TC" do
      opts1 = { :repo_id => @resource3[:repo_id],
                     :rid => @resource3[:id],
                     :filename => "testTopLinkerUpload.csv",
                     :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv"}
      tcl1 = TopContainerLinker.new(opts1[:filepath], "text/csv", @current_user, opts1)
      ao =tcl1.process_row(complete_data_with_container_id)
      expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).to eq(@tc.uri)   
      expect(ao["instances"][0]["instance_type"]).to eq("books")   
      expect(ao["instances"][0]["sub_container"]["type_2"]).to eq("folder")   
      expect(ao["instances"][0]["sub_container"]["indicator_2"]).to eq("Child2")  
      expect(ao["instances"][0]["sub_container"]["barcode_2"]).to eq("child_bc") 
      
  end
  
end
