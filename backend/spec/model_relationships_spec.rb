require 'spec_helper'
require_relative '../app/model/ASModel'
require_relative '../app/model/mixins/relationships'

describe 'Relationships' do

  before(:each) do
    ## Database setup
    [:apple, :banana, :cherry].each do |table|
      $testdb.create_table table do
        primary_key :id
        String :name
        Integer :lock_version, :default => 0

        Integer :suppressed, :default => 0

        String :created_by
        String :last_modified_by
        DateTime :create_time
        DateTime :system_mtime
        DateTime :user_mtime
      end
    end

    $testdb.create_table :fruit_salad_rlshp do
      primary_key :id
      String :sauce
      Integer :banana_id
      Integer :apple_id
      Integer :suppressed, :null => false, :default => 0
      Integer :aspace_relationship_position
      DateTime :system_mtime, :null => false
      DateTime :user_mtime, :null => false
      String :created_by
      String :last_modified_by
    end

    $testdb.create_table :friends_rlshp do
      primary_key :id
      Integer :banana_id_0
      Integer :apple_id_0
      Integer :banana_id_1
      Integer :apple_id_1
      Integer :cherry_id
      Integer :suppressed, :null => false, :default => 0

      Integer :aspace_relationship_position
      DateTime :system_mtime, :null => false
      DateTime :user_mtime, :null => false
      String :created_by
      String :last_modified_by
    end
  end


  after(:each) do
    $testdb.drop_table(:apple)
    $testdb.drop_table(:banana)
    $testdb.drop_table(:cherry)
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
                                     {"type" => "JSONModel(:banana) uri"},
                                     {"type" => "JSONModel(:cherry) uri"}]}
              }
            }
          }
        },
      },
    }')


    JSONModel.stub(:schema_src).with('cherry').and_return('{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "type" => "object",
        "uri" => "/cherries",
        "properties" => {
          "uri" => {"type" => "string", "required" => false},
        },
      },
    }')


    class Cherry < Sequel::Model(:cherry)
      include ASModel
      set_model_scope :global
      corresponds_to JSONModel(:cherry)

      enable_suppression
    end


    class Apple < Sequel::Model(:apple)
      include ASModel
      set_model_scope :global
      corresponds_to JSONModel(:apple)
      clear_relationships

      enable_suppression
    end


    class Banana < Sequel::Model(:banana)
      include ASModel
      set_model_scope :global
      corresponds_to JSONModel(:banana)

      enable_suppression

      clear_relationships
      define_relationship(:name => :fruit_salad,
                          :json_property => 'apples',
                          :contains_references_to_types => proc {[Apple]})

      # Do bananas have friends?  I don't know.  But for the sake of this test
      # they do.
      define_relationship(:name => :friends,
                          :json_property => 'friends',
                          :contains_references_to_types => proc {[Apple, Banana, Cherry]})
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

    apple.delete

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

    banana.my_relationships(:fruit_salad)[0][:system_mtime].to_f.should be >= time
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

    banana.related_records(:friends).count.should eq(1)
    apple.delete
    banana.reload
    banana.related_records(:friends).count.should eq(0)
  end


  it "obviously bananas can be friends with other bananas" do
    banana1 = Banana.create_from_json(JSONModel(:banana).new(:name => "b1"))
    banana2 = Banana.create_from_json(JSONModel(:banana).new(:friends => [{:ref => banana1.uri}]))
    banana1.refresh

    banana2.related_records(:friends)[0].should eq(banana1)
  end


  it "stops two updates from inadvertently overwriting each other's relationship changes" do
    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "granny smith"))
    banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "yogurt"
                                                     }])
    banana = Banana.create_from_json(banana_json)

    apple.name = "modified"

    expect {
      apple.save
    }.to raise_error(Sequel::Plugins::OptimisticLocking::Error)
  end


  it "doesn't worry about relationship changes conflicting unless the involved classes have a reciprocal relationships" do
    cherry = Cherry.create_from_json(JSONModel(:cherry).new)

    banana_json = JSONModel(:banana).from_hash(:friends => [{
                                                              :ref => cherry.uri
                                                            }])

    banana = Banana.create_from_json(banana_json)

    expect {
      cherry.save
    }.to_not raise_error
  end


  it "updates the mtime of all related records when one who participates in a relationship is updated" do
    # Cherry doesn't know about banana
    cherry = Cherry.create_from_json(JSONModel(:cherry).new)

    # But banana is friends with cherry.  Sad, really.
    banana = Banana.create_from_json(JSONModel(:banana).from_hash(:friends => [{
                                                              :ref => cherry.uri
                                                            }]))

    time = (banana.system_mtime.to_f * 1000).to_i
    sleep 0.1

    cherry.update_from_json(JSONModel(:cherry).from_hash(:lock_version => 0))
    banana.refresh

    (banana.system_mtime.to_f * 1000).to_i.should_not eq(time)
  end


  it "creates relationships as suppressed if they relate to suppressed records" do
    cherry = Cherry.create_from_json(JSONModel(:cherry).new)
    cherry.set_suppressed(true)

    banana = Banana.create_from_json(JSONModel(:banana).from_hash(:friends => [{
                                                              :ref => cherry.uri
                                                            }]))

    banana.my_relationships(:friends).first.suppressed.should eq(1)
  end
  
  it "will raise a exception if the optisitmic locking fails" do
    # this is supposed to replicate when a relationship is attempted to be
    # made, but the Sequel throws an optimisitcLocking error
    allow(DB).to receive(:increase_lock_version_or_fail).and_raise(Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of blah"))
    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "IIe"))

    # by default we just try once and raise an error
    attempt =0  
    expect {
      banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "white"
                                                     }])
      attempt += 1 
      Banana.create_from_json(banana_json)
    }.to raise_error(Sequel::NoExistingObject)
    attempt.should eq(1)
  
  end 
    
  it "will retry on optimistic locking failue if told to do so" do  
    # in some situations ( like EAD imports ), we want to retry
    allow(DB).to receive(:increase_lock_version_or_fail).and_raise(Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of blah"))
    apple = Apple.create_from_json(JSONModel(:apple).new(:name => "Lisa"))
    
    # we can tell the db to retry ( it will do 10 times by default ) 
    attempt =0  
    expect {
      DB.open(true, :retries => 6, :retry_on_optimistic_locking_fail => true, :retry_delay => 0 )  do
        banana_json = JSONModel(:banana).new(:apples => [{
                                                       :ref => apple.uri,
                                                       :sauce => "black"
                                                     }])
        attempt += 1 
        Banana.create_from_json(banana_json)
      end
    }.to raise_error(Sequel::NoExistingObject)
    attempt.should eq(6)
  end


  it "updates the mtime of all related records, following nested records back to top-level records as required" do
    # Ditching our fruit salad metaphor for the moment, since this actually
    # happens in real life...

    # We have a digital object
    digital_object = create(:json_digital_object)

    # and an archival object that links to it via instance
    archival_object_json = create(:json_archival_object,
                                  :instances => [
                                    build(:json_instance_digital,
                                          :digital_object => {
                                            :ref => digital_object.uri
                                          })
                                  ])

    archival_object = ArchivalObject[archival_object_json.id]

    start_time = (archival_object[:system_mtime].to_f * 1000).to_i
    sleep 0.1

    # Touch the digital object
    digital_object.refetch
    digital_object.save

    # We want to see the archival object's mtime updated, since that's the
    # top-level record that should be reindexed.  The original bug: only the
    # instance's system_mtime was updated.
    archival_object.refresh
    (archival_object.system_mtime.to_f * 1000).to_i.should_not eq(start_time)
  end
end
