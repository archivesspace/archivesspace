require_relative '../../common/jsonmodel.rb'
require_relative '../lib/crosswalk'


describe "ASpace Crosswalk" do
  
  before(:each) do

    JSONModel::init(:client_mode => true, :strict_mode => true,
                    :url => 'http://example.com')
                
    JSONModel::set_repository('1')

    @xw = ASpaceImport::Crosswalk.new(IO.read('../crosswalks/ead.yml'))
  
  end
  
  
  it "states what kind of crosswalk it is" do
    @xw.to_s.should eq('Crosswalk from http://www.loc.gov/ead/ead.xsd')
  end
  
  
  it "yields a JSONModel when given an xpath" do
    a = []
    
    @xw.models(:xpath => 'c') do |m|
      a.push(m)
    end
    
    a.length.should eq(1)
    a.pop.class.to_s.should eq('JSONModel(:archival_object)')                   
  end
  
  it "yields a JSONModel when given an xpath and a type filter" do
    # TODO - test that when an xpath returns more than 1 model,
    # the @xw.models method can filter with a :type param
  end
  
  
end