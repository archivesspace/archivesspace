require 'spec_helper'
require_relative '../app/model/mixins/dynamic_enums'
require_relative '../app/model/enumeration'

describe 'Enumerations model' do

  before(:all) do
    @enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'test_role_enum',
                                                                           :values => ['battlemage', 'warrior']))

    @enum2 = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'second_test_role_enum',
                                                                            :values => ['mushroom']))

    @enum3 = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'case_test_role_enum',
                                                                            :values => ['frog']))
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

      uses_enums(:property => 'role', :uses_enum => ['test_role_enum'])
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


  it "throws an error if you link to an enumeration that doesn't really exist..." do
    expect {
      @model.new(:role => 'penguin')
    }.to raise_error(RuntimeError)
  end


  it "won't create redundant enum values" do
    expect {
      Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'tomato_enum',
                                                                     :values => ['tomato', 'tomato']))
    }.to raise_error Sequel::UniqueConstraintViolation

    #note: test fails in mysql if the :name value is repeated, even though the first order failed
    expect {
      Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'another_tomato_enum',
                                                                :values => ['tomato']))
    }.to_not raise_error
  end


  it "will preserve the case of enum values" do
    tomato = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'not_another_tomato_enum',
                                                                :values => ['Tomato']))

    Enumeration.to_jsonmodel(tomato)['values'].include?('Tomato').should be(true)
  end


  # created for MySQL-related bug
  it "treats values that differ only in case as separate values" do
    model = Class.new(Sequel::Model(:model_with_enums)) do
      include ASModel
      include DynamicEnums
      uses_enums(:property => 'role', :uses_enum => ['case_test_role_enum'])
    end

    RequestContext.open(:create_enums => true) do
      BackendEnumSource.valid?('case_test_role_enum', 'camel').should be(true)
      BackendEnumSource.valid?('case_test_role_enum', 'Camel').should be(true)
    end

    expect {
      model.new(:role => 'camel')
    }.to_not raise_error

    expect {
      model.new(:role => 'Camel')
    }.to_not raise_error

    Enumeration.to_jsonmodel(@enum3)['values'].include?('camel').should be(true)
    Enumeration.to_jsonmodel(@enum3)['values'].include?('Camel').should be(true)
  end


  it "allows all usages of one enumeration value to be migrated to another" do
    @enum.add_enumeration_value(:value => 'sea cow')
    obj = @model.create(:role => 'sea cow')

    Enumeration[:name => 'test_role_enum'].migrate('sea cow', 'battlemage')

    obj.refresh
    obj.role.should eq('battlemage')
  end


  it "can't migrate from one enumeration set to another" do
    obj = @model.create(:role => 'battlemage')

    expect {
      Enumeration[:name => 'test_role_enum'].migrate('battlemage', 'mushroom')
    }.to raise_error(NotFoundException)
  end

 it "protects non-editable enums from being messed with" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_thingy_enum_delete',
                                                                          :values => ["banana"] ))

	$testdb[:enumeration].filter(:name => 'readonly_thingy_enum_delete').
                                update(:editable => 0)

    expect {
      Enumeration.apply_values(enum, {'values' => [ "more bananas" ]})
    }.to raise_error(AccessDeniedException)

  end


  it "protects readonly enum values from being deleted or transferred" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_role_enum_delete',
                                                                          :values => ['readonly_apple']))


    $testdb[:enumeration_value].filter(:value => 'readonly_apple').
                                update(:readonly => 1)


    expect {
      Enumeration.apply_values(enum, {'values' => [ "banana" ]})
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
