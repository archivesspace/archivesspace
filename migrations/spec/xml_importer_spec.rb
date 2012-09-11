require_relative "spec_helper.rb"


describe 'ASpaceImport::Importer::XmlImporter' do
  
  
  before(:all) do    
    ASpaceImport::Importer.destroy_importers
   
    load "../importers/xml.rb"
 
    repo_id = make_test_repo
    
    opts = {
            :crosswalk => '../crosswalks/ead.yml', 
            :input_file => '../examples/ead/afcu.xml', 
            :importer => 'xml',
            :repo_id => repo_id            
            }
    
     
    @i = ASpaceImport::Importer.create_importer(opts)

     
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

