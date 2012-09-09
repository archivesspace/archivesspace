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
   
    @crosswalk_file = '../crosswalks/ead.yml'

    @input_file = '../examples/ead/afcu.xml'
     
    opts = {:crosswalk => @crosswalk_file, :input_file => @input_file, :importer => 'xml'}
     
    @i = ASpaceImport::Importer.create_importer(opts)

    JSONModel::init( { :client_mode => true, :url => "http://example.com", :strict_mode => false } )

    @klass = Klass.new
    @opts = {:repo_id => '1'}
    @queue = ASpaceImport::ParseQueue.new(opts)    
  end
  
  it "should create a class for pulling an XML file through a YAML crosswalk" do      
    @i.class.name.should eq('XmlImporter')
  end  
  
  it "should return the name of an entity when given an xpath" do

    @i.get_entity('c').should eq('archival_object')
    @i.get_entity('bloop').should be_nil   
  end
  
  it "should run the import" do
    @i.run
  end  

  
  
  
  
end

