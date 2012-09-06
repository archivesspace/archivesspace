require "../lib/bootstrap.rb"
require "../importers/xml.rb"
require_relative "spec_helper.rb"
require 'psych'
require 'nokogiri'


# TODO - Consider writing tests for import method

# Assumptions
# Some nodes in a metadata format should cause entities to be created in AS
# Some nodes in a metadata format should cause properties to be added to an entity
# Some nodes should do both?


describe ASpaceImport::Importer::XmlImporter do
  before(:each) do
   
    @crosswalk_file = make_test_crosswalk

    @input_file = make_test_xml
     
    IO.stub(:read).with('crosswalk.yml'){ @crosswalk_file }
    IO.stub(:read).with('input.xml'){ @input_file }

    opts = {:crosswalk => 'crosswalk.yml', :input_file => 'input.xml', :importer => 'xml'}
     
    @i = ASpaceImport::Importer.create_importer(opts)

    Dir.stub(:glob){ ['stub'] }
    File.stub(:basename){ 'body_part' }
    File.stub_chain("open.read") { make_body_part_schema }

    Net::HTTP.stub(:start){ StubHTTP.new }

    JSONModel::init( { :client_mode => true, :url => "http://example.com", :strict_mode => false } )

    @klass = Klass.new
    @opts = {:repo_id => '1'}
    @queue = JSONModel::Client.queue
    
     
  end
  
  it "should create a class for pulling an XML file through a YAML crosswalk" do      
    @i.class.name.should eq('XmlImporter')
  end  
  
  it "should return the name of an entity when given an xpath" do

    @i.get_entity('muscle').should eq('body_part')
    @i.get_entity('book').should be_nil   
  end
  
  it "should return the name of a property when given a type and an xpath" do
  
    @i.get_property('body_part', 'parent::limb').should eq('location')
  end
  
  it "should run the import" do
    @i.run
  end  

  
  
  
  
end

