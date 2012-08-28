require_relative "../jsonmodel"
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



    # File.stub(:dirname){ 'stub' }
    # File.stub(:join){ 'stub' }
    # File.stub(:join).with("schemas", "*.rb") { 'stub' }
    Dir.stub(:glob){ ['stub'] }
    File.stub(:basename){ 'stub' }
    File.stub_chain("open.read") { schema }
    # File.stub(:open).with('stub'){'stub'}
    

    Net::HTTP.stub(:start){ StubHTTP.new }
    
    JSONModel::init( { :client_mode => true, :url => "http://example.com", :strict_mode => true } )
    
    @klass = Klass.new
  end
  
  it "should supply a class for a loaded schema" do
    
    @klass.JSONModel(:stub).to_s.should eq('JSONModel(:stub)')
    
  end
  
  it "should create an instance when given a hash" do
  
    jo = @klass.JSONModel(:stub).from_hash({"ref_id" => "abc", "title"=> "Stub Object"})
    jo.ref_id.should eq("abc")
  
  end
  
  it "should be able to determine the uri for a class instance give an id and a repo_id" do
  
    @klass.JSONModel(:stub).uri_for(500, :repo_id => "1").should eq('/repositories/1/stubs/500')
  
  end
  
  it "should be able to save an instance of a model" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title=> "Stub Object"})
    jo.save()
    jo.to_hash.has_key?('uri').should be_true
  end
  
  it "should create an instance when given a hash using symbols for keys" do
  
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title=> "Stub Object"})
    jo.ref_id.should eq("abc")
  
  end
  
  it "should have its repo id in its uri after being saved" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title=> "Stub Object"})
    jo.save("repo_id" => 2)
    jo.uri.should eq('/repositories/2/stubs/999')
  end
  
  

end
