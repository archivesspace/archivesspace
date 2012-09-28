require_relative "spec_helper.rb"


describe 'ASpaceImport::Importer::XmlImporter' do
  
  
  before(:all) do    
    ASpaceImport::Importer.destroy_importers
   
    load "../importers/xml.rb"
    
    @opts = {
            :crosswalk => 'ead', 
            :input_file => '../examples/ead/afcu.xml', 
            :importer => 'xml',
            :repo_id => make_test_repo,
            :vocab_uri => make_test_vocab          
            }
    
     
    @i = ASpaceImport::Importer.create_importer(@opts)

     
  end
  
  def create_subject

    subject = JSONModel(:subject).from_hash("terms" => [{"term" => "1981 Heroes", "term_type" => "Cultural context", "vocabulary" => @opts[:vocab_uri]}],
                                            "vocabulary" => @opts[:vocab_uri]
                                            )

    subject.save
  end


  it "lets you create a subject and get it back" do
    id = create_subject
    JSONModel(:subject).find(id).terms[0]["term"].should eq("1981 Heroes")
  end
  
  
  it "should create a class for pulling an XML file through a YAML crosswalk" do      
    @i.class.name.should eq('XmlImporter')
  end  
  
  
  it "should run the import" do
    @i.run
    @i.report
  end  

  
  
  
  
end

