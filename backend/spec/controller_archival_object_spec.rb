require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    test_repo = {
      "repo_code" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repositories', params = JSONModel(:repository).from_hash(test_repo).to_json
    @repo = JSON(last_response.body)["id"]
    @repo_ref = "/repositories/#{@repo}"
  end


  it "lets you create an archival object and get it back" do
    post "/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "1234",
                  "title" => "The archival object title",
                  "repository" => @repo_ref,
                }).to_json

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/archival_objects/#{created["id"]}"

    ao = JSON(last_response.body)

    ao["title"].should eq("The archival object title")
  end


  it "lets you create an archival object with a parent" do
    post "/collections", params = JSONModel(:collection).
      from_hash({
                  "title" => "a collection",
                  "repository" => @repo_ref
                }).to_json

    last_response.should be_ok
    collection = JSON(last_response.body)

    collection_ref = "/collections/#{collection['id']}"

    post "/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "1234",
                  "title" => "parent archival object",
                  "repository" => @repo_ref,
                  "collection" => collection_ref,
                }).to_json

    last_response.should be_ok
    created = JSON(last_response.body)


    post "/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "id_0" => "5678",
                  "title" => "child archival object",
                  "repository" => @repo_ref,
                  "collection" => collection_ref,
                  "parent" => "/archival_objects/#{created['id']}"
                }).to_json


    last_response.should be_ok


    get "/archival_objects/#{created["id"]}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]["title"].should eq("child archival object")
  end



  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    post "/archival_objects", params = JSONModel(:archival_object).
      from_hash({
                  "repository" => @repo_ref,
                }).to_json
    JSONModel::strict_mode(true)

    last_response.should be_ok
    created = JSON(last_response.body)

    known_warnings = ["id_0", "title"]

    (known_warnings - created["warnings"].keys).should eq([])
  end



end
