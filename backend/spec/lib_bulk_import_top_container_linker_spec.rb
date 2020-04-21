require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/top_container_linker"



describe "Top Container Linker" do   

  before(:each) do
    @current_user = User.find(:username => "admin")
    @resource = create_resource({ :title => generate(:generic_title) })
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00007'})
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00008'})
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00009'})
  end


  it "Checks that the linker can run validly on the given file" do
    tmpfilename = File.join(File.dirname(__FILE__), 'testTopLinkerUpload.csv')
    opts = {'rid' => @resource[:id], 'repo_id' => $repo_id}
    tcl = TopContainerLinker.new(tmpfilename, "text/csv", opts, @current_user)
    retval = tcl.run  
    expect(retval).to be true
  end
  
  
end
