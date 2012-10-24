require 'spec_helper'

describe 'Digital Objects controller' do

  before(:each) do
    make_test_repo
  end


  def create_digital_object
    digital_object = JSONModel(:digital_object).from_hash("title" => "a digital object",
                                                          "digital_object_id" => "abc123",
                                                          "extents" => [{
                                                                          "portion" => "whole",
                                                                          "number" => "5 or so",
                                                                          "extent_type" => "reels"
                                                                        }])
    digital_object.save
  end


  it "lets you create a digital object and get it back" do
    id = create_digital_object

    JSONModel(:digital_object).find(id).title.should eq("a digital object")
  end


  it "lets you update a digital object" do
    id = create_digital_object

    digital_object = JSONModel(:digital_object).find(id)

    digital_object.title = "an updated digital object"
    digital_object.save

    JSONModel(:digital_object).find(id).title.should eq("an updated digital object")
  end



  # it "lets you manipulate the record hierarchy" do

  #   resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
  #   id = resource.save

  #   aos = []
  #   ["earth", "australia", "canberra"].each do |name|
  #     ao = JSONModel(:archival_object).from_hash("ref_id" => name,
  #                                                "title" => "archival object: #{name}")
  #     if not aos.empty?
  #       ao.parent = aos.last.uri
  #     end

  #     ao.resource = resource.uri
  #     ao.save
  #     aos << ao
  #   end

  #   tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

  #   tree.to_hash.should eq({
  #                            "jsonmodel_type" => "resource_tree",
  #                            "archival_object" => aos[0].uri,
  #                            "title" => "archival object: earth",
  #                            "children" => [
  #                                           {
  #                                             "jsonmodel_type" => "resource_tree",
  #                                             "archival_object" => aos[1].uri,
  #                                             "title" => "archival object: australia",
  #                                             "children" => [
  #                                                            {
  #                                                              "jsonmodel_type" => "resource_tree",
  #                                                              "archival_object" => aos[2].uri,
  #                                                              "title" => "archival object: canberra",
  #                                                              "children" => []
  #                                                            }
  #                                                           ]
  #                                           }
  #                                          ]
  #                          })


  #   # Now turn it on its head
  #   changed = {
  #     "jsonmodel_type" => "resource_tree",
  #     "archival_object" => aos[2].uri,
  #     "title" => "archival object: canberra",
  #     "children" => [
  #                    {
  #                      "jsonmodel_type" => "resource_tree",
  #                      "archival_object" => aos[1].uri,
  #                      "title" => "archival object: australia",
  #                      "children" => [
  #                                     {
  #                                       "jsonmodel_type" => "resource_tree",
  #                                       "archival_object" => aos[0].uri,
  #                                       "title" => "archival object: earth",
  #                                       "children" => []
  #                                     }
  #                                    ]
  #                    }
  #                   ]
  #   }

  #   JSONModel(:resource_tree).from_hash(changed).save(:resource_id => resource.id)
  #   changed.delete("uri")

  #   tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

  #   tree.to_hash.should eq(changed)
  # end




  # it "can handle asking for the tree of an empty resource" do
  #   resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
  #   id = resource.save

  #   tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

  #   tree.should eq(nil)
  # end


  # it "adds an archival object to a resource when it's added to the tree" do
  #   ao = JSONModel(:archival_object).from_hash("ref_id" => "testing123",
  #                                              "title" => "archival object")
  #   ao_id = ao.save


  #   resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
  #   coll_id = resource.save


  #   tree = JSONModel(:resource_tree).from_hash(:archival_object => ao.uri,
  #                                              :children => [])

  #   tree.save(:resource_id => coll_id)

  #   JSONModel(:archival_object).find(ao_id).resource == "#{@repo}/resources/#{coll_id}"
  # end


  # it "lets you create a resource with a subject" do
  #   vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab",
  #                                            "ref_id" => "abc"
  #                                            )
  #   vocab.save
  #   vocab_uri = JSONModel(:vocabulary).uri_for(vocab.id)
  #   subject = JSONModel(:subject).from_hash("terms" => [{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => vocab_uri}],
  #                                           "vocabulary" => vocab_uri
  #                                           )
  #   subject.save

  #   resource = JSONModel(:resource).from_hash("title" => "a resource",
  #                                             "id_0" => "abc123",
  #                                             "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
  #                                             "subjects" => [subject.uri]
  #                                             )
  #   coll_id = resource.save

  #   JSONModel(:resource).find(coll_id).subjects[0].should eq(subject.uri)
  # end


  # it "can give a list of all resources" do

  #   JSONModel(:resource).from_hash("title" => "coal", "id_0" => "1", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]).save
  #   JSONModel(:resource).from_hash("title" => "wind", "id_0" => "2", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]).save
  #   JSONModel(:resource).from_hash("title" => "love", "id_0" => "3", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]).save

  #   resources = JSONModel(:resource).all

  #   resources.any? { |res| res.title == "coal" }.should be_true
  #   resources.any? { |res| res.title == "wind" }.should be_true
  #   resources.any? { |res| res.title == "love" }.should be_true

  # end

  # it "lets you create a resource with an extent" do
  #   resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
  #   id = resource.save

  #   JSONModel(:resource).find(id).extents.length.should eq(1)
  #   JSONModel(:resource).find(id).extents[0]["portion"].should eq("whole")
  # end


  # it "lets you create a resource with an instance and container" do
  #   resource = JSONModel(:resource).from_hash({
  #     "title" => "a resource", "id_0" => "abc123",
  #     "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
  #     "instances" => [{
  #       "instance_type" => "text",
  #       "container" => {
  #         "type_1" => "A Container",
  #         "indicator_1" => "555-1-2",
  #         "barcode_1" => "00011010010011",
  #       }
  #     }]
  #   })

  #   id = resource.save

  #   JSONModel(:resource).find(id).instances.length.should eq(1)
  #   JSONModel(:resource).find(id).instances[0]["instance_type"].should eq("text")
  #   JSONModel(:resource).find(id).instances[0]["container"]["type_1"].should eq("A Container")
  # end


  # it "lets you edit a resource with an instance and container" do
  #   resource = JSONModel(:resource).from_hash({
  #                                               "title" => "a resource", "id_0" => "abc123",
  #                                               "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
  #                                               "instances" => [{
  #                                                                 "instance_type" => "text",
  #                                                                 "container" => {
  #                                                                   "type_1" => "A Container",
  #                                                                   "indicator_1" => "555-1-2",
  #                                                                   "barcode_1" => "00011010010011",
  #                                                                 }
  #                                                               }]
  #                                             })

  #   id = resource.save

  #   resource = JSONModel(:resource).find(id)

  #   resource.instances[0]["instance_type"] = "audio"

  #   id = resource.save

  #   JSONModel(:resource).find(id).instances[0]["instance_type"].should eq("audio")
  # end

  # it "lets you create a resource with an instance with a container with a location (and the location is resolved)" do
  #   # create a location
  #   location = JSONModel(:location).from_hash({
  #                                               "building" => "129 West 81st Street",
  #                                               "floor" => "5",
  #                                               "room" => "5A",
  #                                               "barcode" => "010101100011",
  #                                             })
  #   location.save

  #   # create the resource with all the instance/container etc
  #   resource = JSONModel(:resource).from_hash({
  #                                               "title" => "a resource", "id_0" => "abc123",
  #                                               "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
  #                                               "instances" => [{
  #                                                                 "instance_type" => "text",
  #                                                                 "container" => {
  #                                                                   "type_1" => "A Container",
  #                                                                   "indicator_1" => "555-1-2",
  #                                                                   "barcode_1" => "00011010010011",
  #                                                                   "container_locations" => [{
  #                                                                     "status" => "current",
  #                                                                     "start_date" => "2012-05-14",
  #                                                                     "location" => location.uri
  #                                                                   }]
  #                                                                 }
  #                                                               }]
  #                                             })


  #   id = resource.save

  #   JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["status"].should eq("current")
  #   JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["resolved"]["location"]["building"].should eq("129 West 81st Street")
  # end


  # it "throws an error if try to link to a non temporary location and have status set to previous" do
  #   # create a location
  #   location = JSONModel(:location).from_hash({
  #                                               "building" => "129 West 81st Street",
  #                                               "floor" => "5",
  #                                               "room" => "5A",
  #                                               "barcode" => "010101100011",
  #                                             })
  #   location.save

  #   # create the resource with all the instance/container etc
  #   expect {
  #     resource = JSONModel(:resource).from_hash({
  #                                               "title" => "a resource", "id_0" => "abc123",
  #                                               "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
  #                                               "instances" => [{
  #                                                                 "instance_type" => "text",
  #                                                                 "container" => {
  #                                                                   "type_1" => "A Container",
  #                                                                   "indicator_1" => "555-1-2",
  #                                                                   "barcode_1" => "00011010010011",
  #                                                                   "container_locations" => [{
  #                                                                                               "status" => "previous",
  #                                                                                               "start_date" => "2012-05-14",
  #                                                                                               "end_date" => "2012-05-18",
  #                                                                                               "location" => location.uri
  #                                                                                             }]
  #                                                                 }
  #                                                               }]
  #                                             })


  #     id = resource.save
  #   }.to raise_error
  # end


  # it "allows linking to a temporary location and with status set to previous" do
  #   # create a location
  #   location = JSONModel(:location).from_hash({
  #                                               "building" => "129 West 81st Street",
  #                                               "floor" => "5",
  #                                               "room" => "5A",
  #                                               "barcode" => "010101100011",
  #                                               "temporary" => "loan",
  #                                             })
  #   location.save

  #   # create the resource with all the instance/container etc
  #   resource = JSONModel(:resource).from_hash({
  #                                                 "title" => "a resource", "id_0" => "abc123",
  #                                                 "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
  #                                                 "instances" => [{
  #                                                                   "instance_type" => "text",
  #                                                                   "container" => {
  #                                                                     "type_1" => "A Container",
  #                                                                     "indicator_1" => "555-1-2",
  #                                                                     "barcode_1" => "00011010010011",
  #                                                                     "container_locations" => [{
  #                                                                                                 "status" => "previous",
  #                                                                                                 "start_date" => "2012-05-14",
  #                                                                                                 "end_date" => "2012-05-18",
  #                                                                                                 "location" => location.uri
  #                                                                                               }]
  #                                                                   }
  #                                                                 }]
  #                                               })


  #     id = resource.save

  #     JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["status"].should eq("previous")
  #     JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["resolved"]["location"]["temporary"].should eq("loan")
  # end


  # it "correctly substitutes the repo_id in nested URIs" do
  #   location = JSONModel(:location).from_hash({
  #                                               "building" => "129 West 81st Street",
  #                                               "floor" => "5",
  #                                               "room" => "5A",
  #                                               "barcode" => "010101100011",
  #                                             })
  #   location_id = location.save

  #   resource = {
  #     "dates" => [],
  #     "extents" => [
  #                   {
  #                     "extent_type" => "cassettes",
  #                     "number" => "1",
  #                     "portion" => "whole"
  #                   }
  #                  ],
  #     "external_documents" => [],
  #     "id_0" => "test",
  #     "instances" => [
  #                     {
  #                       "container" => {
  #                         "barcode_1" => "test",
  #                         "container_locations" => [
  #                                                   {
  #                                                     "end_date" => "2012-10-26",
  #                                                     "location" => "/repositories/#{@repo_id}/locations/#{location_id}",
  #                                                     "note" => "test",
  #                                                     "start_date" => "2012-10-10",
  #                                                     "status" => "current"
  #                                                   }
  #                                                  ],
  #                         "indicator_1" => "test",
  #                         "type_1" => "test"
  #                       },
  #                       "instance_type" => "books",
  #                     }
  #                    ],
  #     "jsonmodel_type" => "resource",
  #     "notes" => [],
  #     "rights_statements" => [],
  #     "subjects" => [],
  #     "title" => "New Resource",
  #   }


  #   resource_id = JSONModel(:resource).from_hash(resource).save

  #   # Set our default repository to nil here since we're really testing the fact
  #   # that the :repo_id parameter is passed through faithfully, and the global
  #   # setting would otherwise mask the error.
  #   #
  #   JSONModel.with_repository(nil) do
  #     container_location = JSONModel(:resource).find(resource_id, :repo_id => @repo_id)["instances"][0]["container"]["container_locations"][0]
  #     container_location["location"].should eq("/repositories/#{@repo_id}/locations/#{location_id}")
  #   end
  # end


  # it "reports an eror when marking a non-temporary location as 'previous'" do
  #   location = JSONModel(:location).from_hash({
  #                                               "building" => "129 West 81st Street",
  #                                               "floor" => "5",
  #                                               "room" => "5A",
  #                                               "barcode" => "010101100011",
  #                                             })
  #   location_id = location.save

  #   resource = JSONModel(:resource).
  #     from_hash("title" => "New Resource",
  #               "id_0" => "test2",
  #               "extents" => [{
  #                               "portion" => "whole",
  #                               "number" => "123",
  #                               "extent_type" => "cassettes"
  #                             }],
  #               "instances" => [{
  #                                 "instance_type" => "microform",
  #                                 "container" => {
  #                                   "type_1" => "test",
  #                                   "indicator_1" => "test",
  #                                   "barcode_1" => "test",
  #                                   "container_locations" => [{
  #                                                               "status" => "previous",
  #                                                               "start_date" => "2012-10-12",
  #                                                               "end_date" => "2012-10-26",
  #                                                               "location" => "/repositories/#{@repo_id}/locations/#{location_id}"
  #                                                             }]
  #                                 }
  #                               }])


  #   err = nil
  #   begin
  #     resource.save
  #   rescue
  #     err = $!
  #   end

  #   err.should be_an_instance_of(ValidationException)
  #   err.errors.keys.should eq(["instances/0/container/container_locations/0/status"])

  # end


  # it "supports resolving locations and subjects" do
  #   location = JSONModel(:location).from_hash({
  #                                               "building" => "129 West 81st Street",
  #                                               "floor" => "5",
  #                                               "room" => "5A",
  #                                               "barcode" => "010101100011",
  #                                             })
  #   location.save

  #   vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab",
  #                                            "ref_id" => "abc"
  #                                            )
  #   vocab.save

  #   subject = JSONModel(:subject).from_hash("terms" => [{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => vocab.uri}],
  #                                           "vocabulary" => vocab.uri
  #                                           )
  #   subject.save



  #   resource_id = JSONModel(:resource).
  #     from_hash("title" => "New Resource",
  #               "id_0" => "test2",
  #               "subjects" => [subject.uri],
  #               "extents" => [{
  #                               "portion" => "whole",
  #                               "number" => "123",
  #                               "extent_type" => "cassettes"
  #                             }],
  #               "instances" => [{
  #                                 "instance_type" => "microform",
  #                                 "container" => {
  #                                   "type_1" => "test",
  #                                   "indicator_1" => "test",
  #                                   "barcode_1" => "test",
  #                                   "container_locations" => [{
  #                                                               "status" => "current",
  #                                                               "start_date" => "2012-10-12",
  #                                                               "end_date" => "2012-10-26",
  #                                                               "location" => location.uri
  #                                                             }]
  #                                 }
  #                               }]).save


  #   resource = JSONModel(:resource).find(resource_id, "resolve[]" => ["subjects", "location"])

  #   # yowza!
  #   resource["instances"][0]["container"]["container_locations"][0]["resolved"]["location"]["barcode"].should eq("010101100011")
  #   resource["resolved"]["subjects"][0]["terms"][0]["term"].should eq("a test subject")
  # end


end
