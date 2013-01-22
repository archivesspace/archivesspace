require 'spec_helper'

describe "Enumeration controller" do

  before(:each) do
    Enumeration.create(:enum_name => "test_enum", :enum_value => "abc")
    Enumeration.create(:enum_name => "test_enum", :enum_value => "def")
  end


  it "can return all defined enumerations" do
    JSONModel(:enumeration).all.find {|obj| obj.name == 'test_enum'}.values.count.should eq(2)
  end

  it "can return a single enumberation" do
    JSONModel(:enumeration).find("test_enum").values.count.should eq(2)
  end

end
