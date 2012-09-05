require "../lib/bootstrap.rb"
require "../importers/xml.rb"
require 'psych'
require 'nokogiri'


# TODO - Consider writing tests for import method

# Assumptions
# Some nodes in a metadata format should cause entities to be created in AS
# Some nodes in a metadata format should cause properties to be added to an entity
# Some nodes should do both?



describe ASpaceImport::Importer::XmlImporter do
  before(:each) do
   
    @crosswalk_file = Psych.dump({
                        'source' => {
                          'format' => 'xml',
                          'schema' => 'greek'
                        },
                        'entities' => {
                          'a' => {
                            'instance' => ['//alpha'],
                            'properties' => {'r' => ['rho']}
                          },
                          'b' => {
                            'instance' => ['beta', 'gamma']
                          },  
                          'g' => {
                            'instance' => ['gamma']
                          }
                        },
                      })
     builder = Nokogiri::XML::Builder.new do |xml|
       xml.root {
         xml.pdq {
           xml.goop = "TEST"
         }
       }
     end
     @input_file = builder.to_xml
     
     
     IO.stub(:read).with('crosswalk.yml'){ @crosswalk_file }
     IO.stub(:read).with('input.xml'){ @input_file }
     
     opts = {:crosswalk => 'crosswalk.yml', :input_file => 'input.xml', :importer => 'xml'}
     
     @i = ASpaceImport::Importer.create_importer(opts)
     
  end
  
  
  it "should create a class for pulling an XML file through a YAML crosswalk" do      
    @i.class.name.should eq('XmlImporter')
  end  
  
  it "should return the name of an entity when given an xpath" do

    @i.lookup_entity_for('alpha').should eq('a')
    expect { @i.lookup_entity_for('gamma') }.to raise_error
    @i.lookup_entity_for('chi').should be_nil
    
  end
  
  it "should return the name of a property when given a type and an xpath" do
  
    @i.lookup_property_for('a', 'rho').should eq('r')
  
  end
    

  
  
  
  
end

