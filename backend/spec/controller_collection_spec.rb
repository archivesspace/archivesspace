require 'spec_helper'

describe 'Collections controller' do

  before(:each) do
    test_repo = {
      "repo_id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repositories', params = { "repository" => JSONModel(:repository).from_hash(test_repo).to_json }
    @repo = JSON(last_response.body)["id"]
  end


  it "lets you create a collection and get it back" do
    post "/collections", params = {
      :collection => JSON({
                            "id_0" => "1234",
                            "title" => "a collection",
                          }),
      :repo_id => @repo,
    }

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/collections/#{created["id"]}"

    collection = JSON(last_response.body)

    collection["title"].should eq("a collection")
  end


  it "lets you manipulate the record hierarchy" do
    post "/collections", params = {
      :collection => JSON({
                            "id_0" => "1234",
                            "title" => "a collection",
                          }),
      :repo_id => @repo,
    }
    last_response.should be_ok
    collection = JSON(last_response.body)


    ids = []
    ["earth", "australia", "canberra"].each do |name|
      opts = {
        :archival_object => JSON({
                                  "id_0" => name,
                                  "title" => "archival object: #{name}",
                                }),
        :repo_id => @repo
      }

      if ids
        opts = opts.merge({
                            :parent => ids.last,
                            :collection => collection["id"]
                          })
      end

      post "/archival_objects", params = opts
      last_response.should be_ok
      created = JSON(last_response.body)

      ids << created["id"]
    end


    get "/collections/#{collection['id']}/tree"
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

    post "/collections/#{collection['id']}/tree", params = {
      :tree => JSON(changed)
    }
    last_response.should be_ok

    get "/collections/#{collection['id']}/tree"
    last_response.should be_ok
    tree = JSON(last_response.body)

    tree.should eq(changed)
  end
end
