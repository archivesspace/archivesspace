require 'spec_helper'

describe "Enumeration controller" do

  before(:each) do
    @enum_id = JSONModel(:enumeration).from_hash(:name => "test_enum",
                                                 :values => ["abc", "def"]).save
  end


  it "can return all defined enumerations" do
    JSONModel(:enumeration).all.find {|obj| obj.name == 'test_enum'}.values.count.should eq(2)
  end


  it "can return a single enumeration by ID" do
    enum = JSONModel(:enumeration).all.find {|obj| obj.name == 'test_enum'}
    JSONModel(:enumeration).find(enum.id).values.count.should eq(2)
  end


  it "can remove an enum value if it isn't used" do
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values -= ["def"]
    obj.save

    JSONModel(:enumeration).find(@enum_id).values.count.should eq(1)
  end

end
