require_relative "spec_helper"
require 'nokogiri'
require 'tmpdir'


describe "ASpaceImport and ASpaceExport modules" do
  
  before(:each) do
    @repo_id = create(:json_repo).id
    puts "Created a new Repo with ID #{@repo_id}"
    @ser = ASpaceExport::serializer(:ead)
    @ser.repo_id = @repo_id
  end
  
  it "should be able to export a Resource and its Tree as EAD" do

    r = FactoryGirl.create(:resource, :repo_id => @repo_id) 
    e = FactoryGirl.create(:extent, :resource_id => r.id) 
    p = FactoryGirl.create(:archival_object, {:repo_id => @repo_id, :root_record_id => r.id})

    10.times { FactoryGirl.create(:archival_object, {:repo_id => @repo_id, :root_record_id => r.id, :parent_id => p.id}) }
          
    ead = @ser.serialize(r)
    
    doc = Nokogiri::XML ead
    ead_file = File.join(Dir::tmpdir, "test_ead_1.xml")
    File.open(ead_file, 'w') { |file| file.write(doc) }
    
  end
  
  it "should be able to import a Resource and its Tree from EAD" do
    
    # reload the ead from the last test
    ead_file = File.join(Dir::tmpdir, "test_ead_1.xml")
    
    @opts = {
            :crosswalk => 'ead', 
            :input_file => ead_file, 
            :importer => 'xml',
            :repo_id => @repo_id,
            :vocab_uri => make_test_vocab          
            }
    
     
    @i = ASpaceImport::Importer.create_importer(@opts)
    @i.run
    
    # Resource id should be 1
    Resource.dataset.filter(:repo_id => @repo_id).each do |r|
    # r = Resource.get_or_die(1)
      ead = @ser.serialize(r)
    
      doc = Nokogiri::XML ead
      ead_file = File.join(Dir::tmpdir, "test_ead_2.xml")
      File.open(ead_file, 'w') { |file| file.write(doc) }    
    end
  end
  
  it "should create a CSV report when importing in DEBUG mode" do
  
    if File.exist?(File.join(Dir::tmpdir, "ead-trace.csv"))
      File.delete(File.join(Dir::tmpdir, "ead-trace.csv"))
    end
      
    $DEBUG = true
    puts "DEBUG" if $DEBUG
      
    ead_file = File.join(Dir::tmpdir, "test_ead_1.xml")
  
    @opts = {
            :crosswalk => 'ead', 
            :input_file => ead_file, 
            :importer => 'xml',
            :repo_id => @repo_id,
            :vocab_uri => make_test_vocab          
            }
  
    @i = ASpaceImport::Importer.create_importer(@opts)
    @i.run
  
    File.exist?(File.join(Dir::tmpdir, "ead-trace.tsv")).should be_true
  
  end

end

