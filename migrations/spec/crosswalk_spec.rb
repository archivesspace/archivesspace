require_relative "spec_helper.rb"

describe "ASpaceImport::Crosswalk" do

  before(:all) do
    ASpaceImport::Crosswalk.init(:crosswalk => 'ead')
    @dummy_class = Class.new do
      extend(ASpaceImport::Crosswalk)
    end
  end

  
  it "should know how to introduce a fresh json object to an event parsing context" do
  
    json = @dummy_class.object_for_node('c', 3, 1)
    json.jsonmodel_type.should eq('archival_object')
  end

  it "should know how to reintroduce a json object to an event parsing context" do
    
    parse_queue = [@dummy_class.object_for_node('c', 3, 1), @dummy_class.object_for_node('c', 4, 1)]
    parse_queue[1].title = 'foo'
    json = @dummy_class.object_for_node('c', 4, 15, parse_queue)
    json.title.should eq('foo')
  end
end