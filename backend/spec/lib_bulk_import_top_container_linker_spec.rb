require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/top_container_linker"


describe "Top Container Linker" do   
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  before(:each) do
    @current_user = User.find(:username => "admin")
    
    @resource = create_resource({ :title => generate(:generic_title), :ead_id => 'hua15019' })
    @tc = create_top_container({:indicator => "Test Box 11", :type => "box"})
        
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
  
  
end
