require_relative "../../common/jsonmodel"
require_relative "../lib/jsonmodel_queue"
require_relative "spec_helper"
require 'net/http'
require 'json'


describe JSONModel::Client do
  
  before(:each) do

    schema = make_test_schema

    Dir.stub(:glob){ ['stub'] }
    File.stub(:basename){ 'stub' }
    File.stub_chain("open.read") { schema }

    Net::HTTP.stub(:start){ StubHTTP.new }
    Net::HTTP::Post

    JSONModel::init( { :client_mode => true, :url => "http://example.com", :strict_mode => false } )

    @klass = Klass.new
    @opts = {:repo_id => '1'}
    @queue = JSONModel::Client.queue
  end
  

  it "should supply a class for a loaded schema" do

    @klass.JSONModel(:stub).to_s.should eq('JSONModel(:stub)')

  end
  
  it "should furnish a method for an object to queue itself" do
    jo = @klass.JSONModel(:stub).from_hash({"ref_id" => "abc", "title"=> "Stub Object"})
    jo.enqueue
    JSONModel::Client.queue.length.should eq(1)
  end
  
  it "should not return a uri for an unsaved object" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title=> "Stub Object"})
    jo.uri.should be_nil
  end    
  
  it "should return a uri for a saved object" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title=> "Stub Object"})
    jo.save("repo_id" => 2)
    jo.uri.should eq('/repositories/2/stubs/999')
  end
  
  it "should save a dequeued object if the object has no references" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title  => "Stub Object"}) 
    jo.enqueue
    @queue.pop
    jo.uri.should eq('/repositories/1/stubs/999')
  end
  
  it "should not save a dequeued object until objects it is waiting for are saved" do
    alpha = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Stub 1"})
    beta = @klass.JSONModel(:stub).from_hash({:ref_id => "def", :title => "Stub 2"})

    beta.wait_for(alpha)
    beta.enqueue
    @queue.pop
    beta.uri.should be_nil
    alpha.enqueue
    @queue.pop
    beta.uri.should eq('/repositories/1/stubs/999')
  end
      
  it "should support after-save hooks and a waiting queue" do
    parent = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Parent Stub"})
    child = @klass.JSONModel(:stub).from_hash({:ref_id => "def", :title => "Stub"})
    parent.add_after_save_hook(Proc.new { child.send("parent=", parent.uri) })
    child.wait_for(parent)
    child.enqueue
    @queue.pop
    child.uri.should be_nil
    parent.enqueue
    @queue.pop
    child.parent.should eq(parent.uri)
    child.uri.should_not be_nil
  end
    
end

