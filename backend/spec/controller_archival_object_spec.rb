require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    test_repo = {
      "repo_code" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repositories', params = JSONModel(:repository).from_hash(test_repo).to_json
    @repo = "/repositories/#{JSON(last_response.body)["id"]}"
  end


  it "lets you create an archival object and get it back" do
    post "#{@repo}/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "1234",
                  "title" => "The archival object title",
                }).to_json

    last_response.should be_ok
    created = JSON(last_response.body)

    get "#{@repo}/archival_objects/#{created["id"]}"

    ao = JSON(last_response.body)

    ao["title"].should eq("The archival object title")
  end


  it "lets you create an archival object with a parent" do
    post "#{@repo}/collections", params = JSONModel(:collection).
      from_hash({
                  "title" => "a collection",
                }).to_json

    last_response.should be_ok
    collection = JSON(last_response.body)

    collection_ref = "#{@repo}/collections/#{collection['id']}"

    post "#{@repo}/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "1234",
                  "title" => "parent archival object",
                  "collection" => collection_ref,
                }).to_json

    last_response.should be_ok
    created = JSON(last_response.body)


    post "#{@repo}/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "5678",
                  "title" => "child archival object",
                  "collection" => collection_ref,
                  "parent" => "#{@repo}/archival_objects/#{created['id']}"
                }).to_json


    last_response.should be_ok


    get "#{@repo}/archival_objects/#{created["id"]}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]["title"].should eq("child archival object")
  end



  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    post "#{@repo}/archival_objects", params = JSONModel(:archival_object).
      from_hash({}).to_json
    JSONModel::strict_mode(true)

    last_response.should be_ok
    created = JSON(last_response.body)

    known_warnings = ["id_0", "title"]

    (known_warnings - created["warnings"].keys).should eq([])
  end


  it "handles updates for an existing archival object" do
    ao = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "1234",
                  "title" => "The archival object title",
                })

    post "#{@repo}/archival_objects", params = ao.to_json

    last_response.should be_ok
    created = JSON(last_response.body)

    ao.title = "A brand new title"

    post "#{@repo}/archival_objects/#{created['id']}", params = ao.to_json

    get "#{@repo}/archival_objects/#{created["id"]}"
    ao = JSON(last_response.body)

    ao["title"].should eq("A brand new title")
  end


end
