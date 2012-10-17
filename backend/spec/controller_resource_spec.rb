require 'spec_helper'

describe 'Resources controller' do

  before(:each) do
    make_test_repo
  end


  it "lets you create a resource and get it back" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    JSONModel(:resource).find(id).title.should eq("a resource")
  end


  it "lets you manipulate the record hierarchy" do

    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = JSONModel(:archival_object).from_hash("ref_id" => name,
                                                 "title" => "archival object: #{name}")
      if not aos.empty?
        ao.parent = aos.last.uri
      end

      ao.resource = resource.uri
      ao.save
      aos << ao
    end

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.to_hash.should eq({
                             "jsonmodel_type" => "resource_tree",
                             "archival_object" => aos[0].uri,
                             "title" => "archival object: earth",
                             "children" => [
                                            {
                                              "jsonmodel_type" => "resource_tree",
                                              "archival_object" => aos[1].uri,
                                              "title" => "archival object: australia",
                                              "children" => [
                                                             {
                                                               "jsonmodel_type" => "resource_tree",
                                                               "archival_object" => aos[2].uri,
                                                               "title" => "archival object: canberra",
                                                               "children" => []
                                                             }
                                                            ]
                                            }
                                           ]
                           })


    # Now turn it on its head
    changed = {
      "jsonmodel_type" => "resource_tree",
      "archival_object" => aos[2].uri,
      "title" => "archival object: canberra",
      "children" => [
                     {
                       "jsonmodel_type" => "resource_tree",
                       "archival_object" => aos[1].uri,
                       "title" => "archival object: australia",
                       "children" => [
                                      {
                                        "jsonmodel_type" => "resource_tree",
                                        "archival_object" => aos[0].uri,
                                        "title" => "archival object: earth",
                                        "children" => []
                                      }
                                     ]
                     }
                    ]
    }

    JSONModel(:resource_tree).from_hash(changed).save(:resource_id => resource.id)
    changed.delete("uri")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.to_hash.should eq(changed)
  end



  it "lets you update a resource" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    resource.title = "an updated resource"
    resource.save

    JSONModel(:resource).find(id).title.should eq("an updated resource")
  end


  it "can handle asking for the tree of an empty resource" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.should eq(nil)
  end


  it "adds an archival object to a resource when it's added to the tree" do
    ao = JSONModel(:archival_object).from_hash("ref_id" => "testing123",
                                               "title" => "archival object")
    ao_id = ao.save


    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    coll_id = resource.save


    tree = JSONModel(:resource_tree).from_hash(:archival_object => ao.uri,
                                               :children => [])

    tree.save(:resource_id => coll_id)

    JSONModel(:archival_object).find(ao_id).resource == "#{@repo}/resources/#{coll_id}"
  end


  it "lets you create a resource with a subject" do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab",
                                             "ref_id" => "abc"
                                             )
    vocab.save
    vocab_uri = JSONModel(:vocabulary).uri_for(vocab.id)
    subject = JSONModel(:subject).from_hash("terms" => [{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => vocab_uri}],
                                            "vocabulary" => vocab_uri
                                            )
    subject.save

    resource = JSONModel(:resource).from_hash("title" => "a resource",
                                              "id_0" => "abc123",
                                              "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
                                              "subjects" => [subject.uri]
                                              )
    coll_id = resource.save

    JSONModel(:resource).find(coll_id).subjects[0].should eq(subject.uri)
  end


  it "can give a list of all resources" do

    JSONModel(:resource).from_hash("title" => "coal", "id_0" => "1", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]).save
    JSONModel(:resource).from_hash("title" => "wind", "id_0" => "2", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]).save
    JSONModel(:resource).from_hash("title" => "love", "id_0" => "3", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]).save

    resources = JSONModel(:resource).all

    resources.any? { |res| res.title == "coal" }.should be_true
    resources.any? { |res| res.title == "wind" }.should be_true
    resources.any? { |res| res.title == "love" }.should be_true

  end

  it "lets you create a resource with an extent" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    JSONModel(:resource).find(id).extents.length.should eq(1)
    JSONModel(:resource).find(id).extents[0]["portion"].should eq("whole")
  end


  it "lets you create a resource with an instance and container" do
    resource = JSONModel(:resource).from_hash({
      "title" => "a resource", "id_0" => "abc123",
      "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
      "instances" => [{
        "instance_type" => "text",
        "container" => {
          "type_1" => "A Container",
          "indicator_1" => "555-1-2",
          "barcode_1" => "00011010010011",
        }
      }]
    })

    id = resource.save

    JSONModel(:resource).find(id).instances.length.should eq(1)
    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq("text")
    JSONModel(:resource).find(id).instances[0]["container"]["type_1"].should eq("A Container")
  end


  it "lets you edit a resource with an instance and container" do
    resource = JSONModel(:resource).from_hash({
                                                "title" => "a resource", "id_0" => "abc123",
                                                "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
                                                "instances" => [{
                                                                  "instance_type" => "text",
                                                                  "container" => {
                                                                    "type_1" => "A Container",
                                                                    "indicator_1" => "555-1-2",
                                                                    "barcode_1" => "00011010010011",
                                                                  }
                                                                }]
                                              })

    id = resource.save

    resource = JSONModel(:resource).find(id)

    resource.instances[0]["instance_type"] = "audio"

    id = resource.save

    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq("audio")
  end

  it "lets you create a resource with an instance with a container with a location (and the location is resolved)" do
    # create a location
    location = JSONModel(:location).from_hash({
                                                "building" => "129 West 81st Street",
                                                "floor" => "5",
                                                "room" => "5A",
                                                "barcode" => "010101100011",
                                              })
    location.save

    # create the resource with all the instance/container etc
    resource = JSONModel(:resource).from_hash({
                                                "title" => "a resource", "id_0" => "abc123",
                                                "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
                                                "instances" => [{
                                                                  "instance_type" => "text",
                                                                  "container" => {
                                                                    "type_1" => "A Container",
                                                                    "indicator_1" => "555-1-2",
                                                                    "barcode_1" => "00011010010011",
                                                                    "container_locations" => [{
                                                                      "status" => "current",
                                                                      "start_date" => "2012-05-14",
                                                                      "location" => location.uri
                                                                    }]
                                                                  }
                                                                }]
                                              })


    id = resource.save

    JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["status"].should eq("current")
    JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["resolved"]["location"]["building"].should eq("129 West 81st Street")
  end

end
