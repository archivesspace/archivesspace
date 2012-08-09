require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    @repo = make_test_repo
  end


  def create_archival_object(opts = {})
    post "#{@repo}/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "1234",
                  "id_1" => "5678",
                  "title" => "The archival object title",
                }.merge(opts)).to_json

    last_response.should be_ok
    JSON(last_response.body)
  end


  it "lets you create an archival object and get it back" do
    created = create_archival_object

    get "#{@repo}/archival_objects/#{created["id"]}"

    ao = JSON(last_response.body)

    ao["title"].should eq("The archival object title")
  end


  it "lets you create an archival object with a parent" do
    post "#{@repo}/collections", params = JSONModel(:collection).
      from_hash({"title" => "a collection"}).to_json

    last_response.should be_ok
    collection = JSON(last_response.body)

    collection_ref = "#{@repo}/collections/#{collection['id']}"

    created = create_archival_object("collection" => collection_ref)

    create_archival_object("id_0" => "4567",
                           "collection" => collection_ref,
                           "title" => "child archival object",
                           "parent" => "#{@repo}/archival_objects/#{created['id']}")


    get "#{@repo}/archival_objects/#{created["id"]}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]["title"].should eq("child archival object")
  end



  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    post "#{@repo}/archival_objects", params = JSONModel(:archival_object).
      from_hash({"id_0" => "abc"}).to_json
    JSONModel::strict_mode(true)

    last_response.should be_ok
    created = JSON(last_response.body)

    known_warnings = ["title"]

    (known_warnings - created["warnings"].keys).should eq([])
  end


  it "handles updates for an existing archival object" do
    created = create_archival_object

    get "#{@repo}/archival_objects/#{created["id"]}"
    ao = JSONModel(:archival_object).from_json(last_response.body)
    ao.title = "A brand new title"

    post "#{@repo}/archival_objects/#{created['id']}", params = ao.to_json

    get "#{@repo}/archival_objects/#{created["id"]}"
    ao = JSON(last_response.body)

    ao["title"].should eq("A brand new title")
  end


  it "treats updates as being replaces, not additions" do
    created = create_archival_object

    get "#{@repo}/archival_objects/#{created["id"]}"
    ao = JSONModel(:archival_object).from_json(last_response.body)
    ao.id_1 = nil
    post "#{@repo}/archival_objects/#{created['id']}", params = ao.to_json

    get "#{@repo}/archival_objects/#{created["id"]}"
    ao = JSON(last_response.body)

    ao.has_key?("id_1").should be_false

  end


  it "lets you create an archival object with a subject" do
    post "/subjects", params = JSONModel(:subject).
      from_hash({"term" => "a test subject", "term_type" => "Cultural context"}).to_json

    last_response.should be_ok
    subject = JSON(last_response.body)

    subject_ref = "/subjects/#{subject['id']}"
    
    created = create_archival_object("id_0" => "4567",
                           "subjects" => [subject_ref],
                           "title" => "child archival object")


    get "#{@repo}/archival_objects/#{created["id"]}"
    last_response.should be_ok

    ao = JSON(last_response.body)

    ao["subjects"][0].should eql(subject_ref)
  end


  it "can resolve subjects for you" do
    post "/subjects", params = JSONModel(:subject).
      from_hash({"term" => "a test subject", "term_type" => "Cultural context"}).to_json

    last_response.should be_ok
    subject = JSON(last_response.body)

    subject_ref = "/subjects/#{subject['id']}"

    created = create_archival_object("id_0" => "4567",
                           "subjects" => [subject_ref],
                           "title" => "child archival object")


    get "#{@repo}/archival_objects/#{created["id"]}?resolve[]=subjects"
    last_response.should be_ok

    ao = JSON(last_response.body)

    ao["subjects"][0]["term"].should eq("a test subject")
  end



end
