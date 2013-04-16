require_relative "spec_helper.rb"
require 'ostruct'

describe 'ASpaceImport::Importer::XmlImporter' do
  
  
  before(:each) do    

    @opts = {
            :crosswalk => 'ead', 
            :input_file => '../examples/ead/archon-tracer.xml', 
            :importer => 'xml',
            :repo_id => 2,
            :vocab_uri => build(:json_vocab).class.uri_for(2, :repo_id => 2)          
            }

    @i = ASpaceImport::Importer.create_importer(@opts)     
  end


  describe :regexify do
    it "converts xpaths and depth offsets into regular expressions for matching xpaths in a crosswalk definition" do
      
      expect("/foo").to match(@i.regexify("foo"))
      expect("ancestor::foo").to match(@i.regexify("/path/to/foo", -3))
      expect("child::foo").to match(@i.regexify("/path/to/foo", 1))
      expect("child::foo").to_not match(@i.regexify("/path/to/foo", 2))
      expect("child::to/child::foo").to match(@i.regexify("/path/to/foo", 2))
      expect("child::*/child::*/child::corpname").to match(@i.regexify("/way/down/in/an/ead/is/a/corpname", 3))     
    end
    
    it "can match xpaths to a regular expression using attributes" do
      
      @i.instance_variable_set(:@attr_selectors, [{}, {}, {:@bar => 'doh'}, {}])
      
      # expect("child::foo/toq").to match(@i.regexify("/path/to/foo/toq", 2))
      expect("child::foo[@bar='doh']/toq").to match(@i.regexify("/path/to/foo/toq", 2))
      
    end  
    
  end
  
  
  it "should create a class for pulling an XML file through a YAML crosswalk" do      
    @i.class.name.should eq('XmlImporter')
  end


  it "should run" do
    @i.instance_eval do
      def @parse_queue.save
        OpenStruct.new(:code => '200',
                       :body => {'saved' => {'123' => '/garbage/url/123'}}.to_json)
      end

      set_up_tracer
    end

    def @i.debugging?; true; end

    @i.run
  end
end

