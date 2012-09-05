require_relative "../../common/jsonmodel"
require_relative "../lib/jsonmodel_queue"
require 'net/http'
require 'json'


describe JSONModel do
  
  
  before(:all) do

    BACKEND_SERVICE_URL = 'http://example.com'

    class StubHTTP
      def request (req)
        StubResponse.new
      end
      def code
        "200"
      end
      def body
        { 'id' => '999' }.to_json
      end
    end

    class Klass
      include JSONModel
    end
  end

  before(:each) do

    schema = '{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "type" => "object",
        "uri" => "/repositories/:repo_id/stubs",
        "properties" => {
          "uri" => {"type" => "string", "required" => false},
          "ref_id" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
          "component_id" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
          "title" => {"type" => "string", "minLength" => 1, "required" => true},

          "level" => {"type" => "string", "minLength" => 1, "required" => false},
          "parent" => {"type" => "JSONModel(:stub) uri", "required" => false},
          "collection" => {"type" => "JSONModel(:stub) uri", "required" => false},

          "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:stub) uri_or_object"}},
        },

        "additionalProperties" => false,
      },
    }'

    Dir.stub(:glob){ ['stub'] }
    File.stub(:basename){ 'stub' }
    File.stub_chain("open.read") { schema }

    Net::HTTP.stub(:start){ StubHTTP.new }

    JSONModel::init( { :client_mode => true, :url => "http://example.com", :strict_mode => false } )

    @klass = Klass.new
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
    jo.dequeue
    jo.uri.should eq('/repositories/1/stubs/999')
  end
    
  it "should support after-save hooks and reference requirements" do
    parent = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Parent Stub"})
    child = @klass.JSONModel(:stub).from_hash({:ref_id => "def", :title => "Stub"})
    parent.add_after_save_hook(Proc.new { child.send("parent=", parent.uri) })
    child.add_reference(parent)
    child.try_save({:repo_id => '1'}).should be_false
    parent.try_save({:repo_id => '1'})
    parent.after_save    
    child.parent.should eq(parent.uri)
    child.save.should_not be_false
  end
    
end

