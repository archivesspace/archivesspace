require 'spec_helper'
require_relative '../app/model/dynamic_enums'
require_relative '../app/model/enumeration'

describe 'Enumerations model' do

  before(:each) do
    DB.open do |db|
      db.create_table :model_with_enums do
        primary_key :id
        Integer :role_id
        Integer :lock_version, :default => 0
        Date :create_time
        Date :last_modified
      end
    end

    @model = Class.new(Sequel::Model(:model_with_enums)) do
      include ASModel
      include DynamicEnums

      uses_enums(:property => 'role', :uses_enum => 'test_role_enum')
    end


    Enumeration.create(:enum_name => 'test_role_enum',
                       :enum_value => 'battlemage')

    Enumeration.create(:enum_name => 'test_role_enum',
                       :enum_value => 'warrior')

    Enumeration.create(:enum_name => 'second_test_role_enum',
                       :enum_value => 'mushroom')

  end


  after(:each) do
    DB.open do |db|
      db.drop_table(:model_with_enums)
    end
  end


  it "Automatically turns enumeration values into links to the enumeration table" do
    obj = @model.new(:role => 'battlemage')

    # As if by magic, the string 'battlemage' has been resolved to an ID linking
    # to the enumeration.
    obj.values[:role_id].should eq(Enumeration[:enum_value => 'battlemage'].id)
  end


  it "Throws an error if you link to an enumeration that doesn't really exist" do
    expect {
      @model.new(:role => 'penguin')
    }.to raise_error
  end


  it "Allows all usages of one enumeration value to be migrated to another" do
    obj = @model.create(:role => 'battlemage')

    obj.role.should eq('battlemage')

    from = Enumeration[:enum_value => 'battlemage'].id
    to = Enumeration[:enum_value => 'warrior'].id

    Enumeration.migrate(from, to)

    obj.refresh
    obj.role.should eq('warrior')
  end


  it "Refuses to migrate from one enumeration set to another" do
    obj = @model.create(:role => 'battlemage')

    from = Enumeration[:enum_value => 'battlemage'].id
    to = Enumeration[:enum_value => 'mushroom'].id

    expect {
      Enumeration.migrate(from, to)
    }.to raise_error
  end



end
