if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('common:test')
end

require_relative "../jsonmodel"
require_relative "../jsonmodel_client"
require 'net/http'
require 'json'
require 'ostruct'

RSpec.configure do |config|

  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end
end



describe JSONModel do

  before(:all) do

    BACKEND_SERVICE_URL = 'http://example.com'

    class StubHTTP
      def request (uri, req, body = nil, &block)
        response = OpenStruct.new(:code => '200')
        block ? yield(self) : self
      end
      def code
        "200"
      end
      def body
        { 'id' => '999' }.to_json
      end

      def method_missing(*args)
        # I don't care
      end

    end

    class Klass
      include JSONModel
    end
  end


  before(:each) do

    allow(JSONModel::Client::EnumSource).to receive(:fetch_enumerations).and_return({})


    schema = '{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "version" => 1,

        "type" => "object",
        "uri" => "/repositories/:repo_id/stubs",
        "properties" => {
          "uri" => {"type" => "string", "required" => false},
          "publish" => {"type" => "boolean", "required" => false},
          "ref_id" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
          "component_id" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
          "title" => {"type" => "string", "minLength" => 1, "required" => true},

          "names" => {
            "type" => "array",
            "items" => {"type" => "JSONModel(:stub) uri_or_object"},
          },

          "level" => {"type" => "string", "minLength" => 1, "required" => false},
          "parent" => {"type" => "JSONModel(:stub) uri", "required" => false},
          "collection" => {"type" => "JSONModel(:stub) uri", "required" => false},

          "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:stub) uri_or_object"}},
        },

        "additionalProperties" => false,
      },
    }'


    child_schema = '{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "version" => 1,

        "type" => "object",
        "parent" => "stub",

        "uri" => "/repositories/:repo_id/child_stubs",

        "properties" => {
          "childproperty" => {"type" => "string", "required" => false},
        },

        "additionalProperties" => false,
      },
    }'


    AppConfig[:plugins] = []

    allow(JSONModel).to receive(:schema_src).and_return(schema)
    allow(JSONModel).to receive(:schema_src).with("stub").and_return(schema)
    allow(JSONModel).to receive(:schema_src).with("child_stub").and_return(child_schema)

    allow(Net::HTTP::Persistent).to receive(:new).and_return( StubHTTP.new )

    JSONModel::init(:client_mode => true,
                    :url => "http://example.com",
                    :strict_mode => true,
                    :allow_other_unmapped => true)


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
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Stub Object"})
    jo.save("repo_id" => 2)
    jo.to_hash.has_key?('uri').should be_truthy
  end

  it "should create an instance when given a hash using symbols for keys" do

    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Stub Object"})
    jo.ref_id.should eq("abc")

  end

  it "should have its repo id in its uri after being saved" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Stub Object"})
    jo.save("repo_id" => 2)
    jo.uri.should eq('/repositories/2/stubs/999')
  end

  it "should inherit properties from the inherited object via extend/$ref" do
    @klass.JSONModel(:child_stub).to_s.should eq('JSONModel(:child_stub)')
    child_jo = @klass.JSONModel(:child_stub).from_hash({:title => "hello", :ref_id => "abc", :childproperty => "yeah", :ignoredproperty => "oh no"})
    child_jo.save("repo_id" => 2)
    child_jo.to_hash.has_key?('childproperty').should be_truthy
    child_jo.to_hash.has_key?('uri').should be_truthy
    child_jo.to_hash.has_key?('ignoredproperty').should be_falsey
  end

  it "can query its schema for the types of things" do
    @klass.JSONModel(:stub).type_of("names/items").should eq @klass.JSONModel(:stub)
  end

  it "should return an empty array for nil properties of type array" do
    jo = @klass.JSONModel(:stub).from_hash({:ref_id => "abc", :title => "Stub Object"})
    jo.names.class.should eq(Array)
    jo.names.length.should eq(0)
  end


  it "should support streaming" do
    JSONModel::HTTP::stream('/', {}) do |response|
      # response
      response.should_not be(nil)
    end
  end

  describe "jsonmodel utils" do
    describe "set_publish_flags" do
      before(:each) do
        @p_false = @klass.JSONModel(:stub).from_hash({"ref_id" => "abc", "title"=> "Stub Object", "publish" => false})
        @p_true = @klass.JSONModel(:stub).from_hash({"ref_id" => "abc", "title"=> "Stub Object", "publish" => true})


        @np_resource = @klass.JSONModel(:stub).from_hash(
          {"ref_id" => "abc", 
           "title"=> "Stub Object", 
           "publish" => false,
           "subjects" => [@p_false, @p_true]}
        )

        @p_resource = @klass.JSONModel(:stub).from_hash(
          {"ref_id" => "abc", 
           "title"=> "Stub Object", 
           "publish" => true,
           "subjects" => [@p_false, @p_true]}
        )

        @p_nested_resource = @klass.JSONModel(:stub).from_hash(
          {"ref_id" => "abc", 
           "title"=> "Stub Object", 
           "publish" => true,
           "subjects" => [@p_resource, @np_resource]}
        )

        @np_nested_resource = @klass.JSONModel(:stub).from_hash(
          {"ref_id" => "abc", 
           "title"=> "Stub Object", 
           "publish" => false,
           "subjects" => [@p_resource, @np_resource]}
        )
      end

      it "set publish flags based on parent if parent publish == false" do
        JSONModel.set_publish_flags!(@np_resource)

        expect(@np_resource['subjects'][0]['publish']).to eq(false)
        expect(@np_resource['subjects'][1]['publish']).to eq(false)
      end

      it "leave publish flags alone if parent publish == true" do
        JSONModel.set_publish_flags!(@p_resource)

        expect(@p_resource['subjects'][0]['publish']).to eq(false)
        expect(@p_resource['subjects'][1]['publish']).to eq(true)
      end

      it "set publish flags based on parent if parent publish == false (doubly nested)" do
        JSONModel.set_publish_flags!(@np_nested_resource)

        expect(@np_nested_resource['subjects'][0]['publish']).to eq(false)
        expect(@np_nested_resource['subjects'][1]['publish']).to eq(false)

        expect(@np_nested_resource['subjects'][0]['subjects'][0]['publish']).to eq(false)
        expect(@np_nested_resource['subjects'][0]['subjects'][1]['publish']).to eq(false)
        expect(@np_nested_resource['subjects'][1]['subjects'][0]['publish']).to eq(false)
        expect(@np_nested_resource['subjects'][1]['subjects'][1]['publish']).to eq(false)
      end

      it "set publish flags based on parent if parent publish == false (doubly nested)" do
        JSONModel.set_publish_flags!(@p_nested_resource)

        expect(@p_nested_resource['subjects'][0]['publish']).to eq(true)
        expect(@p_nested_resource['subjects'][1]['publish']).to eq(false)

        expect(@p_nested_resource['subjects'][0]['subjects'][0]['publish']).to eq(false)
        expect(@p_nested_resource['subjects'][0]['subjects'][1]['publish']).to eq(true)
        expect(@p_nested_resource['subjects'][1]['subjects'][0]['publish']).to eq(false)
        expect(@p_nested_resource['subjects'][1]['subjects'][1]['publish']).to eq(false)
      end
    end
  end 
end
