require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/top_container_linker"

#TODO: Have to redo this test because of the recent refactoring


describe "Top Container Linker" do   

  before(:each) do
    @current_user = User.find(:username => "admin")
    @resource = create_resource({ :title => generate(:generic_title) })
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00007'})
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00008'})
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00009'})
  end


#  it "Checks that the linker can run validly on the given file" do
#    tmpfilename = File.join(File.dirname(__FILE__), 'testTopLinkerUpload.csv')
#    opts = {'rid' => @resource[:id], 'repo_id' => $repo_id}
#    tcl = TopContainerLinker.new(tmpfilename, "text/csv", @current_user, opts)
#    report = tcl.run  
#    expect(report).to be_a(BulkImportReport)
#    expect(report.row_count).to be > 0
#  end
  
  
end
