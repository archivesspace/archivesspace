require 'spec_helper'

describe 'Collections controller' do

  before(:each) do
    test_repo = {
      "repo_code" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repositories', params = JSONModel(:repository).from_hash(test_repo).to_json
    @repo = JSON(last_response.body)["id"]
  end


  it "lets you create a collection and get it back" do
    post "/repositories/#{@repo}/collections", params = JSONModel(:collection).
      from_hash({
                  "title" => "a collection",
                }).to_json

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/repositories/#{@repo}/collections/#{created["id"]}"

    collection = JSON(last_response.body)

    collection["title"].should eq("a collection")
  end


  it "lets you manipulate the record hierarchy" do
    post "/repositories/#{@repo}/collections", params = JSONModel(:collection).
      from_hash({
                  "id_0" => "1234",
                  "title" => "a collection",
                }).to_json

    last_response.should be_ok
    collection = JSON(last_response.body)


    ids = []
    ["earth", "australia", "canberra"].each do |name|
      ao = JSONModel(:archival_object).from_hash({
                                                   "id_0" => name,
                                                   "title" => "archival object: #{name}",
                                                 })
      if not ids.empty?
        ao.parent = "/repositories/#{@repo}/archival_objects/#{ids.last}"
        ao.collection = "/repositories/#{@repo}/collections/#{collection['id']}"
      end

      post "/repositories/#{@repo}/archival_objects", params = ao.to_json
      last_response.should be_ok
      created = JSON(last_response.body)

      ids << created["id"]
    end


    get "/repositories/#{@repo}/collections/#{collection['id']}/tree"
    last_response.should be_ok
    tree = JSON(last_response.body)

    tree.should eq({
                     "collection_id" => collection['id'],
                     "title" => "a collection",
                     "children" => [{
                                      "id" => ids[0],
                                      "title" => "archival object: earth",
                                      "children" => [
                                                     {
                                                       "id" => ids[1],
                                                       "title" => "archival object: australia",
                                                       "children" => [
                                                                      {
                                                                        "id" => ids[2],
                                                                        "title" => "archival object: canberra",
                                                                        "children" => []
                                                                      }
                                                                     ]
                                                     }
                                                    ]
                                    }]
                   })


    # Now turn it on its head
    changed = {
      "collection_id" => collection['id'],
      "title" => "a collection",
      "children" => [{
                       "id" => ids[2],
                       "title" => "archival object: canberra",
                       "children" => [
                                      {
                                        "id" => ids[1],
                                        "title" => "archival object: australia",
                                        "children" => [
                                                       {
                                                         "id" => ids[0],
                                                         "title" => "archival object: earth",
                                                         "children" => []
                                                       }
                                                      ]
                                      }
                                     ]
                     }]
    }

    post "/repositories/#{@repo}/collections/#{collection['id']}/tree", params = {
      :tree => JSON(changed)
    }
    last_response.should be_ok

    get "/repositories/#{@repo}/collections/#{collection['id']}/tree"
    last_response.should be_ok
    tree = JSON(last_response.body)

    tree.should eq(changed)
  end
end
