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
    expect(obj.values[:role_id]).to eq(EnumerationValue[:value => 'battlemage'].id)
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
    }.not_to raise_error
  end


  it "will preserve the case of enum values" do
    tomato = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'not_another_tomato_enum',
                                                                :values => ['Tomato']))

    expect(Enumeration.to_jsonmodel(tomato)['values'].include?('Tomato')).to be_truthy
  end


  # created for MySQL-related bug
  it "treats values that differ only in case as separate values" do
    model = Class.new(Sequel::Model(:model_with_enums)) do
      include ASModel
      include DynamicEnums
      uses_enums(:property => 'role', :uses_enum => ['case_test_role_enum'])
    end

    RequestContext.open(:create_enums => true) do
      expect(BackendEnumSource.valid?('case_test_role_enum', 'camel')).to be_truthy
      expect(BackendEnumSource.valid?('case_test_role_enum', 'Camel')).to be_truthy
    end

    expect {
      model.new(:role => 'camel')
    }.not_to raise_error

    expect {
      model.new(:role => 'Camel')
    }.not_to raise_error

    expect(Enumeration.to_jsonmodel(@enum3)['values'].include?('camel')).to be_truthy
    expect(Enumeration.to_jsonmodel(@enum3)['values'].include?('Camel')).to be_truthy
  end


  it "allows all usages of one enumeration value to be migrated to another" do
    @enum.add_enumeration_value(:value => 'sea cow')
    obj = @model.create(:role => 'sea cow')

    Enumeration[:name => 'test_role_enum'].migrate('sea cow', 'battlemage')

    obj.refresh
    expect(obj.role).to eq('battlemage')
  end


  it "can't migrate from one enumeration set to another" do
    obj = @model.create(:role => 'battlemage')

    expect {
      Enumeration[:name => 'test_role_enum'].migrate('battlemage', 'mushroom')
    }.to raise_error(NotFoundException)
  end

  it "returns not found exception when migrating (old) value does not exist" do
    expect {
      Enumeration[:name => 'test_role_enum'].migrate('i_do_not_exist', 'battlemage')
    }.to raise_error(NotFoundException, /Can't find a value/)
  end

  it "protects non-editable enums from being messed with" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_thingy_enum_delete',
                                                                          :values => ["banana", "cherry"] ))

	  $testdb[:enumeration].filter(:name => 'readonly_thingy_enum_delete').
                                update(:editable => 0)

    expect {
      Enumeration.apply_values(enum, {'values' => [ "more bananas" ]})
    }.to raise_error(AccessDeniedException, /Cannot modify a non-editable enumeration/)

    expect {
      Enumeration[:name => 'readonly_thingy_enum_delete'].migrate('banana', 'cherry')
    }.to raise_error(EnumerationMigrationFailed, /Can't migrate values for non-editable enumeration/)
  end

  it "protects readonly enum values from being deleted or transferred" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_role_enum_delete',
                                                                          :values => ['readonly_apple']))


    $testdb[:enumeration_value].filter(:value => 'readonly_apple').
                                update(:readonly => 1)


    expect {
      Enumeration.apply_values(enum, {'values' => [ "banana" ]})
    }.to raise_error(AccessDeniedException, /Can't remove read-only enumeration value/)

    expect {
      enum.migrate('readonly_apple', 'anything')
    }.to raise_error(EnumerationMigrationFailed, /Can't transfer from a read-only enumeration value/)
  end


  it "returns readonly values" do
    enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => 'readonly_role_enum_select',
                                                                          :values => ['readonly_apple']))


    $testdb[:enumeration_value].filter(:value => 'readonly_apple').
                                update(:readonly => 1)


    expect(Enumeration.to_jsonmodel(enum)['readonly_values'].include?('readonly_apple')).to be_truthy
  end


  # TODO: Move these tests: These tests should go in a more generalized spec, but there doesn't seem to be a suitable spec yet.
  # These tests are here for now because the query by string functionality on models inheriting from ASModel is first used with Enumeration.
  describe "query via to_jsonmodel" do
    before(:all) do
      @q_enum_name = "test_enum_querying"
      @q_enum = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => @q_enum_name, :values => ['test_value']))
    end

    it "can query Enumerations by ID" do
      json = Enumeration.to_jsonmodel(@q_enum[:id])
      expect(json).not_to be_nil
      expect(json['id']).to eq(@q_enum[:id])
      expect(json['name']).to eq(@q_enum_name)
    end

    it "allows a query by string" do
      json = Enumeration.to_jsonmodel(@q_enum_name, :query => "name")
      expect(json).not_to be_nil
      expect(json['id']).to eq(@q_enum[:id])
      expect(json['name']).to eq(@q_enum_name)
    end
  end
end
