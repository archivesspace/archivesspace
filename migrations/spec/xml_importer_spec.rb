require_relative "spec_helper.rb"


describe 'ASpaceImport::Importer::XmlImporter' do
  
  
  before(:all) do    
    ASpaceImport::Importer.destroy_importers
   
    load "../importers/xml.rb"
    
    @opts = {
            :crosswalk => 'ead', 
            :input_file => '../examples/ead/afcu.xml', 
            :importer => 'xml',
            :repo_id => rand(20),
            :vocab_uri => make_test_vocab          
            }
    
     
    @i = ASpaceImport::Importer.create_importer(@opts)
     
  end
  
  
  it "should create a class for pulling an XML file through a YAML crosswalk" do      
    @i.class.name.should eq('XmlImporter')
  end  
end

