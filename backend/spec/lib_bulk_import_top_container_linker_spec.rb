require "spec_helper"
require_relative "../app/lib/bulk_import/container_instance_handler"
require_relative "../app/lib/bulk_import/top_container_linker"


describe "Top Container Linker" do   
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  
  before(:each) do
    @current_user = User.find(:username => "admin")
   
    @loc = create_location()
    @cp = create_container_profile()
    
    create_resource1_data()
    create_resource2_data()
    create_resource3_data()
    
   end
   
   def create_top_container(topcont, resource_uri, cih)
      tc = JSONModel(:top_container).new._always_valid!
      tc.type = topcont["top_container_type"]
      tc.indicator = topcont["top_container_indicator"]
      tc.barcode = topcont["top_container_barcode"] if topcont["top_container_barcode"]
      tc.repository = { "ref" => resource_uri.split("/")[0..2].join("/") }
      tc = cih.save(tc, TopContainer)
      key = cih.key_for(tc, resource_uri)
      cih.instance_variable_get(:@top_containers)[key] = tc
      tc
    end
    
    def create_resource1_data()
      @resource = create_resource({ :title => generate(:generic_title), :ead_id => 'hua15019' })
     
      opts1 = { :repo_id => @resource[:repo_id],
                :rid => @resource[:id],
                :filename => "testTopLinkerUpload.csv",
                :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv",
                :validate => false,
                :initialize_enums => true}
              
      @tcl1 = TopContainerLinker.new(opts1[:filepath], "text/csv", @current_user, opts1)
      @cih1 = @tcl1.instance_variable_get(:@cih)
        
      @tc = create_top_container({"top_container_indicator" => "Box 1", "top_container_type" => "box", "top_container_barcode" => "121212"}, @resource.uri, @cih1)
      
      optsexcel = { :repo_id => @resource[:repo_id],
                     :rid => @resource[:id],
                     :filename => "testTopLinkerUpload.xlsx",
                     :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.xlsx",
                     :ref_id => "",
                     :aoid => "",
                     :position => "" ,
                     :validate => false,
                     :initialize_enums => true}
            
      @tclexcel = TopContainerLinker.new(optsexcel[:filepath], "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", @current_user, optsexcel)
      @cihexcel = @tclexcel.instance_variable_get(:@cih)
      create_top_container({"top_container_indicator" => "Box 1", "top_container_type" => "box", "top_container_barcode" => "121213"}, @resource.uri, @cihexcel)
      
      create_resource1_top_containers
                    
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00007', :instances => [build(:json_instance,
          :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00008', :instances => [build(:json_instance,
          :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00009', :instances => [build(:json_instance,
          :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00010', :instances => [build(:json_instance,
          :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource.uri}, :ref_id => 'hua15019c00011', :instances => [build(:json_instance,
          :sub_container => build(:json_sub_container, :top_container => {:ref => @tc.uri}))]})
    end
    
    def create_resource2_data()
      @resource2 = create_resource({ :title => generate(:generic_title), :ead_id => 'hua12345' })
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource2.uri}, :ref_id => 'hua12345c00007'})     
        
          
      opts2 = { :repo_id => @resource2[:repo_id],
                         :rid => @resource2[:id],
                         :filename => "testTopLinkerUpload.csv",
                         :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv",
                         :validate => false,
                         :initialize_enums => true}
      
      @tcl2 = TopContainerLinker.new(opts2[:filepath], "text/csv", @current_user, opts2)
      @cih2 = @tcl2.instance_variable_get(:@cih)
      create_resource2_top_containers
          
    end
    
    def create_resource3_data()
      @resource3 = create_resource({ :title => generate(:generic_title), :ead_id => 'hua6789' })
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource3.uri}, :ref_id => 'hua6789c00007'})
          
      create_archival_object({:title => generate(:generic_title), :resource => {:ref => @resource3.uri}, :ref_id => 'hua6789c00008'})
        
                    
      opts3 = { :repo_id => @resource3[:repo_id],
            :rid => @resource3[:id],
            :filename => "testTopLinkerUpload.csv",
            :filepath => BULK_FIXTURES_DIR + "/testTopLinkerUpload.csv",
            :validate => false,
            :initialize_enums => true}
          
      @tcl3 = TopContainerLinker.new(opts3[:filepath], "text/csv", @current_user, opts3)
      @cih3 = @tcl3.instance_variable_get(:@cih)
      create_resource3_top_containers
    end
    
    def create_resource1_top_containers()
      create_top_container({"top_container_indicator" => "Test Box 2", "top_container_type" => "box", "top_container_barcode" => "98765"}, @resource.uri, @cih1)
      create_top_container({"top_container_indicator" => "Test Box 11", "top_container_type" => "box", "top_container_barcode" => "54555"}, @resource.uri, @cih1)
      create_top_container({"top_container_indicator" => "Test Box 2", "top_container_type" => "box", "top_container_barcode" => "98766"}, @resource.uri, @cihexcel)
      create_top_container({"top_container_indicator" => "Test Box 11", "top_container_type" => "box", "top_container_barcode" => "54556"}, @resource.uri, @cihexcel)
    end
    
    def create_resource2_top_containers()
      create_top_container(row_1_data, @resource2.uri, @cih2)
    end
    
    def create_resource3_top_containers()
      create_top_container(row_2_data, @resource3.uri, @cih3)
      create_top_container(row_3_data, @resource3.uri, @cih3)
      create_top_container(complete_data_with_type_ind, @resource3.uri, @cih3)
    end

    
   def row_1_data
    {"ead_id" => "hua12345", 
      "ref_id"=>"hua12345c00007",
      "instance_type"=>"books", 
      "top_container_indicator"=>"Box 1", 
      "top_container_type"=>"box", 
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
      "top_container_type"=>"box", 
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
      "top_container_type"=>"box", 
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
      "top_container_type"=>"box", 
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
   
#    it "reads in csv spreadsheet and runs with no errors" do
#      report = @tcl1.run
#      expect(report.terminal_error).to eq(nil)
#      expect(report.row_count).to eq(5)
#      expect(report.rows[0].errors).to eq([])
#      expect(report.rows[1].errors).to eq([])
#      expect(report.rows[2].errors).to eq([])
#      expect(report.rows[3].errors).to eq([])
#      expect(report.rows[4].errors).to eq([])
#  end
#
#
#  it "reads in excel spreadsheet and runs with no errors" do
#      report = @tclexcel.run
#      expect(report.terminal_error).to eq(nil)
#      expect(report.row_count).to eq(5)
#      expect(report.rows[0].errors).to eq([])
#      expect(report.rows[1].errors).to eq([])
#      expect(report.rows[2].errors).to eq([])
#      expect(report.rows[3].errors).to eq([])
#      expect(report.rows[4].errors).to eq([])
#  end
  
  it "validates that adding the same type-indicator to two separate AOs with different resources will create two top containers" do
    ao =@tcl2.process_row(row_1_data)
    expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).not_to eq(@tc.uri)   
  end
  
  it "validates that adding the same type-indicator to two separate AOs with the same resource will create one top container" do
    ao =@tcl3.process_row(row_2_data)
    ao2 =@tcl3.process_row(row_3_data)
    
    expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).to eq(ao2["instances"][0]["sub_container"]["top_container"]["ref"])   
  end
  
  it "validates that adding all possible data with a container_id creates an links the TC" do
      ao =@tcl3.process_row(complete_data_with_container_id)
      expect(ao["instances"][0]["sub_container"]["top_container"]["ref"]).to eq(@tc.uri)   
      expect(ao["instances"][0]["instance_type"]).to eq("books")   
      expect(ao["instances"][0]["sub_container"]["type_2"]).to eq("folder")   
      expect(ao["instances"][0]["sub_container"]["indicator_2"]).to eq("Child2")  
      expect(ao["instances"][0]["sub_container"]["barcode_2"]).to eq("child_bc")  
  end
  
end
