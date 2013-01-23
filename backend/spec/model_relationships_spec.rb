require 'spec_helper'
require_relative '../app/model/ASModel'
require_relative '../app/model/relationships'

describe 'Relationships' do

  before(:each) do
    ## Database setup
    [:apple, :banana].each do |table|
      $testdb.create_table table do
        primary_key :id
        String :name
        Integer :lock_version, :default => 0
        Date :create_time
        Date :last_modified
      end
    end

    $testdb.create_table :app_fruit_salad_ban do
      primary_key :id
      String :sauce
      Integer :banana_id
      Integer :apple_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false
    end

    $testdb.create_table :app_friends_ban do
      primary_key :id
      Integer :banana_id
      Integer :apple_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false
    end
  end


  after(:each) do
    $testdb.drop_table(:apple)
    $testdb.drop_table(:banana)
    $testdb.drop_table(:app_fruit_salad_ban)
    $testdb.drop_table(:app_friends_ban)
  end


  before(:each) do
    ## Some minimal JSONModel instances
    JSONModel.stub(:schema_src).with('apple').and_return('{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "type" => "object",
        "uri" => "/apples",
        "properties" => {
          "uri" => {"type" => "string", "required" => false},
          "bananas" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "subtype" => "ref",
              "properties" => {
                "ref" => {"type" => [{"type" => "JSONModel(:banana) uri"}]}
              }
            }
          }
        },
      },
    }')

    JSONModel.stub(:schema_src).with('banana').and_return('{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "type" => "object",
        "uri" => "/bananas",
        "properties" => {
          "uri" => {"type" => "string", "required" => false},
          "apples" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "subtype" => "ref",
              "properties" => {
                "ref" => {"type" => [{"type" => "JSONModel(:apple) uri"}]}
              }
            }
          },
          "friends" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "subtype" => "ref",
              "properties" => {
                "ref" => {"type" => "JSONModel(:apple) uri"}
              }
            }
          }
        },
      },
    }')


    class Apple < Sequel::Model(:apple)
      include ASModel
      include Relationships
      set_model_scope :global
      corresponds_to JSONModel(:apple)
      clear_relationships
    end


    class Banana < Sequel::Model(:banana)
      include ASModel
      include Relationships
      set_model_scope :global
      corresponds_to JSONModel(:banana)

      clear_relationships
      define_relationship(:name => :fruit_salad,
                          :json_property => 'apples',
                          :contains_references_to_types => proc {[Apple]})

      # Do bananas have friends?  I don't know.  But for the sake of this test
      # they do.
      define_relationship(:name => :friends,
                          :json_property => 'friends',
                          :contains_references_to_types => proc {[Apple]})
    end


    # Need to do this in two steps because of the mutual relationship between
    # the two classes...
    class Apple < Sequel::Model(:apple)
      define_relationship(:name => :fruit_salad,
                          :json_property => 'bananas',
                          :contains_references_to_types => proc {[Banana]})
    end
  end


  it "can represent relationships with properties" do

    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith"))

    banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "yogurt"
                                                     }])
    banana = Banana.create_from_json(banana_json)

    # Check the forwards relationship
    Banana.to_jsonmodel(banana).apples[0]['ref'].should eq(apple.uri)
    Banana.to_jsonmodel(banana).apples[0]['sauce'].should eq('yogurt')

    # And the reciprocal one
    Apple.to_jsonmodel(apple).bananas[0]['ref'].should eq(banana.uri)
    Apple.to_jsonmodel(apple).bananas[0]['sauce'].should eq('yogurt')
  end


  it "doesn't differentiate between updates made from opposing sides of the relationship" do

    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith"))

    # Create a fruit salad relationship by adding an apple to a banana
    #
    # Hopefully that's the strangest thing I'll type today...
    banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "yogurt"
                                                     }])
    banana = Banana.create_from_json(banana_json)

    # Check the forwards relationship
    Banana.to_jsonmodel(banana).apples[0]['ref'].should eq(apple.uri)
    Banana.to_jsonmodel(banana).apples[0]['sauce'].should eq('yogurt')

    # Clear the relationship by updating the apple to remove the banana
    apple.update_from_json(JSONModel(:apple).new(:name => "granny smith",
                                                 :lock_version => 0))

    # Now the banana has no apples listed
    banana.refresh
    Banana.to_jsonmodel(banana).apples.should eq([])
  end


  it "deletes relationships if one side of the relationship is deleted" do
    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith"))
    banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "yogurt"
                                                     }])
    banana = Banana.create_from_json(banana_json)


    # Now you see it
    banana.my_relationships(:fruit_salad).count.should_not be(0)

    Apple.prepare_for_deletion(Apple.filter(:id => apple.id))

    # Now you don't
    banana.reload
    banana.my_relationships(:fruit_salad).count.should eq(0)
  end


  it "stores a last modified time on each relationship" do
    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith"))
    banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "yogurt"
                                                     }])
    time = Time.now.to_f
    banana = Banana.create_from_json(banana_json)

    banana.my_relationships(:fruit_salad)[0][0][:last_modified].to_f.should be >= time
  end


  it "blows up if you link to a non-existent URI" do
    expect {
    Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith",
                                                 :bananas => [{
                                                                :ref => "/bananas/12345",
                                                                :sauce => "rasberry"
                                                              }]))
    }.to raise_error(ReferenceError)
  end

  it "deletes reciprocal relationship instances when deleting a record" do
    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith"))
    banana = Banana.create_from_json(JSONModel(:banana).new(:friends => [{:ref => apple.uri}]))

    banana.linked_records(:friends).count.should eq(1)
    apple.delete
    banana.reload
    banana.linked_records(:friends).count.should eq(0)
  end

end
