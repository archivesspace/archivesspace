require_relative "spec_helper"




describe "JSONModel::Client" do
  
  before (:each) do
    make_test_repo
  end

  it "should supply a class for a loaded schema" do

    JSONModel(:resource).to_s.should eq('JSONModel(:resource)')

  end
  
  it "should not return a uri for an unsaved object" do
    jo = JSONModel(:resource).from_hash({:id_0 => "abc", :title=> "Fake Resurce"})
    jo.uri.should be_nil
  end    
  
  it "should return a uri for a saved object" do
    jo = JSONModel(:resource).from_hash({:id_0 => "abc", :title=> "Fake Resource"})

    jo.save
    jo.uri.should match(/\/repositories\/[0-9]*\/[0-9]*/)
  end
  
  it "should hold off saving an object while it is waiting for other unsaved objects" do
    alpha = JSONModel(:resource).from_hash({:id_0 => "abc", :title=> "Fake Resurce A"})
    beta = JSONModel(:resource).from_hash({:id_0 => "def", :title=> "Fake Resurce B"})

    beta.wait_for(alpha)
    beta.save_or_wait
    
    beta.uri.should be_nil

    alpha.save_or_wait
    
    alpha.uri.should match(/\/repositories\/[0-9]*\/resources\/[0-9]*/)    
    beta.uri.should match(/\/repositories\/[0-9]*\/resources\/[0-9]*/)
    
  end
      
  it "should support after-save hooks and a waiting queue" do
    parent = JSONModel(:archival_object).from_hash({:ref_id => "abc", :title => "Parent Object"})
    child = JSONModel(:archival_object).from_hash({:ref_id => "def", :title => "Child Object"})
    grandchild = JSONModel(:archival_object).from_hash({:ref_id => "ghi", :title => "Grand Child Object"})
    
    parent.add_after_save_hook(Proc.new { child.send("parent=", parent.uri) })    
    child.add_after_save_hook(Proc.new { grandchild.send("parent=", child.uri) })

    
    child.wait_for(parent)

    grandchild.wait_for(child)


    grandchild.save_or_wait

    grandchild.uri.should be_nil


    child.save_or_wait

    child.uri.should be_nil


    parent.save_or_wait

    grandchild.parent.should eq(child.uri)
    grandchild.uri.should match(/\/repositories\/[0-9]*\/archival_objects\/[0-9]*/)
    child.parent.should eq(parent.uri)
    child.uri.should match(/\/repositories\/[0-9]*\/archival_objects\/[0-9]*/)
  end
  

    
end

