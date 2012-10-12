require_relative "spec_helper"




describe "JSONModel::Queueable" do
  
  before (:each) do
    make_test_repo
  end
  
  it "should hold off saving an object while it is waiting for other unsaved objects" do
    
    JSONModel(:resource).class_eval do
      include JSONModel::Queueable
    end
    
    alpha = JSONModel(:resource).from_hash({:id_0 => "abc", 
                                            :title=> "Fake Resurce A", 
                                            :extents => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]})
    beta = JSONModel(:resource).from_hash({:id_0 => "def", 
                                            :title=> "Fake Resurce B",
                                            :extents => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]})

    beta.wait_for(alpha)
    beta.save_or_wait
    
    beta.uri.should be_nil

    alpha.save_or_wait
    
    alpha.uri.should match(/\/repositories\/[0-9]*\/resources\/[0-9]*/)    
    beta.uri.should match(/\/repositories\/[0-9]*\/resources\/[0-9]*/)
    
  end
      
  it "should support after-save hooks and a waiting queue" do
    
    JSONModel(:archival_object).class_eval do
      include JSONModel::Queueable
    end
    
    parent = JSONModel(:archival_object).from_hash({:ref_id => "abc", :title => "Parent Object"})
    child = JSONModel(:archival_object).from_hash({:ref_id => "def", :title => "Child Object"})
    grandchild = JSONModel(:archival_object).from_hash({:ref_id => "ghi", :title => "Grand Child Object"})
    
    parent.after_save { child.send("parent=", parent.uri) }
    child.after_save { grandchild.send("parent=", child.uri) }

    
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

