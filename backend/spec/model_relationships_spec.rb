require 'spec_helper'
require_relative '../app/model/ASModel'
require_relative '../app/model/mixins/relationships'

describe 'Relationships' do

  before(:each) do
    ## Database setup
    [:apple, :banana].each do |table|
      $testdb.create_table table do
        primary_key :id
        String :name
        Integer :lock_version, :default => 0
        DateTime :create_time
        DateTime :last_modified
      end
    end

    $testdb.create_table :fruit_salad_rlshp do
      primary_key :id
      String :sauce
      Integer :banana_id
      Integer :apple_id
      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false
    end

    $testdb.create_table :friends_rlshp do
      primary_key :id
      Integer :banana_id_0
      Integer :apple_id_0
      Integer :banana_id_1
      Integer :apple_id_1

      Integer :aspace_relationship_position
      DateTime :last_modified, :null => false
    end
  end


  after(:each) do
    $testdb.drop_table(:apple)
    $testdb.drop_table(:banana)
    $testdb.drop_table(:fruit_salad_rlshp)
    $testdb.drop_table(:friends_rlshp)
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
                "ref" => {"type" => [{"type" => "JSONModel(:apple) uri"},
                                     {"type" => "JSONModel(:banana) uri"}]}
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
                          :contains_references_to_types => proc {[Apple, Banana]})
    end


    # Need to do this in two steps because of the mutual relationship between
    # the two classes...
    class Apple < Sequel::Model(:apple)
      define_relationship(:name => :fruit_salad,
                          :json_property => 'bananas',
                          :contains_references_to_types => proc {[Banana]})

      define_relationship(:name => :friends,
                          :json_property => 'friends',
                          :contains_references_to_types => proc {[Apple, Banana]})

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
    apple.refresh
    apple.update_from_json(JSONModel(:apple).new(:name => "granny smith",
                                                 :lock_version => 1))

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

    banana.my_relationships(:fruit_salad)[0][:last_modified].to_f.should be >= time
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


  it "obviously bananas can be friends with other bananas" do
    banana1 = Banana.create_from_json(JSONModel(:banana).new(:name => "b1"))
    banana2 = Banana.create_from_json(JSONModel(:banana).new(:friends => [{:ref => banana1.uri}]))
    banana1.refresh

    banana2.linked_records(:friends)[0].should eq(banana1)
  end

end
