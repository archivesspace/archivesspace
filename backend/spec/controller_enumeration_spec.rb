require 'spec_helper'

describe "Enumeration controller" do

  before(:each) do
    enum = $testdb[:enumeration].filter(:name => 'test_enum')
    if enum.count > 0
      $testdb[:enumeration_value].filter(:enumeration_id => enum.first[:id]).delete
      enum.delete
    end

    @enum_id = JSONModel(:enumeration).from_hash(:name => "test_enum",
                                                 :values => ["abc", "def"]).save

    if !$testdb.table_exists?(:controller_enum_model)
      $testdb.create_table(:controller_enum_model) do
        primary_key :id
        Integer :my_enum_id
        Integer :lock_version, :default => 0
        DateTime :create_time
        DateTime :system_mtime
        DateTime :user_mtime
        String :created_by
        String :last_modified_by
      end

      $testdb.alter_table(:controller_enum_model) do
        add_foreign_key([:my_enum_id], :enumeration_value, :key => :id)
      end
    end

    @model = Class.new(Sequel::Model(:controller_enum_model)) do
      include ASModel
      include DynamicEnums

      set_model_scope :global

      uses_enums(:property => 'my_enum', :uses_enum => 'test_enum')
    end
  end



  it "can return all defined enumerations" do
    JSONModel(:enumeration).all.find {|obj| obj.name == 'test_enum'}.values.count.should eq(2)
  end


  it "can return a single enumeration by ID" do
    enum = JSONModel(:enumeration).all.find {|obj| obj.name == 'test_enum'}
    JSONModel(:enumeration).find(enum.id).values.count.should eq(2)
  end


  it "can add and remove values (if the value isn't used)" do
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values += ["unused"]
    obj.save

    obj.values -= ["unused"]
    obj.save

    JSONModel(:enumeration).find(@enum_id).values.count.should eq(2)
  end


  it "can't remove values that are being used" do
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values += ["new_value"]
    obj.save

    value = EnumerationValue[:value => 'new_value']
    record = @model.create(:my_enum_id => value.id)

    obj.values -= ['new_value']

    expect {
      obj.save
    }.to raise_error(ConflictException)
  end


  it "can migrate a value to get rid of it" do
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values += ["new_value"]
    obj.save

    value = EnumerationValue[:value => 'new_value']
    record = @model.create(:my_enum_id => value.id)

    old_time = record[:system_mtime]

    request = JSONModel(:enumeration_migration).from_hash(:enum_uri => obj.uri,
                                                          :from => 'new_value',
                                                          :to => 'abc')
    request.save

    record.refresh
    record[:system_mtime].should_not eq(old_time)
    record[:my_enum_id].should_not eq(value.id)
  end
  
  it "can have a default value" do
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.default_value.should be_nil
    
    val = obj.values[0]
    
    obj.default_value = val
    obj.save
    
    obj = nil
    
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.default_value.should eq(val)
  end
  
  it "can quietly ignore a non-viable default value" do
    obj = JSONModel(:enumeration).find(@enum_id)
    
    default = "banana"
    
    obj.values.should_not include(default)
    
    obj.default_value = default
    obj.save
    
    obj = nil
    
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.default_value.should be_nil
    
  end
  
  it "can suppress and unsuppress  values" do
    obj = JSONModel(:enumeration).find(@enum_id)
    
    val = obj.enumeration_values[0]
   
    enum_val = JSONModel(:enumeration_value).find(val['id'])
    enum_val.set_suppressed(true) 
    
    obj = nil
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values.should_not include(val["value"])
    
    enum_val.set_suppressed(false) 
    
    obj = nil
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values.should include(val["value"])
    
  end

  it "will be keep suppressed values if other changes are made" do
    obj = JSONModel(:enumeration).find(@enum_id)
    
    val = obj.enumeration_values[0]
    @model.create(:my_enum_id => val['id'])
   
    enum_val = JSONModel(:enumeration_value).find(val['id'])
    enum_val.set_suppressed(true) 
    
    
    obj = nil
    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values.should_not include(val["value"])
    
    vals = obj.values

    new_val = "moremoremore" 
    obj.values += [new_val]
    obj.save
    
    # make sure we refresh 
    obj = nil 
    obj = JSONModel(:enumeration).find(@enum_id)

    obj.values.should eq( vals << new_val )
   
    obj.enumeration_values.map { |v| v["value"] }.should include(val["value"])
    
    
  end

  

  it "can change positions of  values" do
    obj = JSONModel(:enumeration).find(@enum_id)
    val = obj.enumeration_values[0]
    position = obj.enumeration_values.length 

    enum_val = JSONModel(:enumeration_value).find(val['id'])
    response = JSON.parse( JSONModel::HTTP.post_form("#{enum_val.uri}/position", :position => position ).body )  
   
    response["id"].should eq(val["id"])
    response["status"].should eq("Updated")

    obj = JSONModel(:enumeration).find(@enum_id)
    obj.values.last.should eq(val["value"])
  end
    

end
