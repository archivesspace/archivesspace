require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    test_repo = {
      "repo_id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repositories', params = { "repository" => JSONModel(:repository).from_hash(test_repo).to_json }
    @repo = JSON(last_response.body)["id"]
  end


  it "lets you create an archival object and get it back" do
    post "/archival_objects", params = {
      :archival_object => JSON({
                                 "id_0" => "1234",
                                 "title" => "The archival object title",
                               }),
      :repo_id => @repo,
    }

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/archival_objects/#{created["id"]}"

    ao = JSON(last_response.body)

    ao["title"].should eq("The archival object title")
  end


  it "lets you create an archival object with a parent" do
    post "/collections", params = {
      :collection => JSON({
                            "id_0" => "1234",
                            "title" => "a collection",
                          }),
      :repo_id => @repo,
    }

    last_response.should be_ok
    collection = JSON(last_response.body)

    post "/archival_objects", params = {
      :archival_object => JSON({
                                 "id_0" => "1234",
                                 "title" => "parent archival object",
                               }),
      :repo_id => @repo,
    }

    last_response.should be_ok
    created = JSON(last_response.body)


    post "/archival_objects", params = {
      :archival_object => JSON({
                                "id_0" => "5678",
                                "title" => "child archival object",
                              }),
      :repo_id => @repo,
      :parent => created["id"],
      :collection => collection["id"]
    }

    last_response.should be_ok


    get "/archival_objects/#{created["id"]}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]["title"].should eq("child archival object")
  end



  it "warns about missing properties" do
    post "/archival_objects", params = {
      :archival_object => JSON({}),
      :repo_id => @repo
    }

    last_response.should be_ok
    created = JSON(last_response.body)

    known_warnings = ["id_0", "title"]

    (known_warnings - created["warnings"].keys).should eq([])
  end



end
