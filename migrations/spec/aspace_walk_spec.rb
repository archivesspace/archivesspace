require "../lib/bootstrap.rb"
require 'psych'

# TODO - Consider writing tests for import method

describe ASpaceWalk do
  before(:each) do
    @yaml = Psych.dump({'source_format' => "TEST",
                        'objects' => {
                                      'obj1' => {'xpath' => '//hot'},
                                      'obj2' => {'xpath' => '//damn'}
                                      }
                       })
    
  end
  
  
  
  it "should give me 5 when I go to get 5" do
    ASpaceWalk.get_5.should == 5
  end
  
  it "should create a class for a YAML crosswalk" do
    w = ASpaceWalk.load_walk(@yaml).new    
    w.class.to_s.should eq('ASpaceWalk from TEST')
  end
  
  it "should say whether a source node begets an object" do
    w = ASpaceWalk.load_walk(@yaml).new
    w.class.causes_object?('hot').should be_true
    w.class.causes_object?('cold').should be_false
    
  end
end

