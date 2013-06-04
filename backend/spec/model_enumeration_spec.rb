require 'spec_helper'
require_relative '../app/model/mixins/dynamic_enums'
require_relative '../app/model/enumeration'

describe 'Enumerations model' do

  before(:all) do
    @enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'test_role_enum',
                                                                           :values => ['battlemage', 'warrior']))

    @enum2 = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'second_test_role_enum',
                                                                            :values => ['mushroom']))
  end


  before(:each) do
    $testdb.create_table :model_with_enums do
      primary_key :id
      Integer :role_id
      Integer :lock_version, :default => 0
      DateTime :create_time
      DateTime :system_mtime
      DateTime :user_mtime
      String :created_by
      String :last_modified_by
    end

    @model = Class.new(Sequel::Model(:model_with_enums)) do
      include ASModel
      include DynamicEnums

      uses_enums(:property => 'role', :uses_enum => 'test_role_enum')
    end
  end


  after(:each) do
    $testdb.drop_table(:model_with_enums)
  end


  it "automatically turns enumeration values into links to the enumeration table" do
    obj = @model.new(:role => 'battlemage')

    # As if by magic, the string 'battlemage' has been resolved to an ID linking
    # to the enumeration.
    obj.values[:role_id].should eq(EnumerationValue[:value => 'battlemage'].id)
  end


  it "throws an error if you link to an enumeration that doesn't really exist" do
    expect {
      @model.new(:role => 'penguin')
    }.to raise_error
  end


  it "allows all usages of one enumeration value to be migrated to another" do
    @enum.add_enumeration_value(:value => 'sea cow')
    obj = @model.create(:role => 'sea cow')

    Enumeration[:name => 'test_role_enum'].migrate('sea cow', 'battlemage')

    obj.refresh
    obj.role.should eq('battlemage')
  end


  it "refuses to migrate from one enumeration set to another" do
    obj = @model.create(:role => 'battlemage')

    expect {
      Enumeration[:name => 'test_role_enum'].migrate('battlemage', 'mushroom')
    }.to raise_error
  end


  it "protects readonly enum values from being deleted or transferred" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_role_enum_delete',
                                                                          :values => ['readonly_apple']))


    $testdb[:enumeration_value].filter(:value => 'readonly_apple').
                                update(:readonly => 1)


    expect {
      Enumeration.apply_values(enum, {'values' => []})
    }.to raise_error(AccessDeniedException)

    expect {
      enum.migrate('readonly_apple', 'anything')
    }.to raise_error(AccessDeniedException)
  end


  it "returns readonly values" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_role_enum_select',
                                                                          :values => ['readonly_apple']))


    $testdb[:enumeration_value].filter(:value => 'readonly_apple').
                                update(:readonly => 1)


    Enumeration.to_jsonmodel(enum)['readonly_values'].include?('readonly_apple').should be(true)
  end

end
