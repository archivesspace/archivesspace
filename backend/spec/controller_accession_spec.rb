require 'spec_helper'

describe 'Accession controller' do

  before(:each) do
    test_repo = {
      "repo_code" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repositories', params = JSONModel(:repository).from_hash(test_repo).to_json
    @repo = JSON(last_response.body)["id"]
    @repo_ref = "/repositories/#{@repo}"
  end


  it "lets you create an accession and get it back" do
    post "/accessions", params = JSON({
                                        "repository" => @repo_ref,
                                        "accession_id_0" => "1234",
                                        "title" => "The accession title",
                                        "content_description" => "The accession description",
                                        "condition_description" => "The condition description",
                                        "accession_date" => "2012-05-03",
                                      })

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/accessions/#{created["id"]}"

    acc = JSON(last_response.body)

    acc["title"].should eq("The accession title")
  end


  it "fails when you try to update an accession that doesn't exist" do
    post "/accessions/99999", params = JSON({"repository" => @repo_ref})

    last_response.status.should eq(404)
    JSON(last_response.body)["error"].should eq("Accession not found")
  end


  it "warns about missing properties" do
    post "/accessions", params = JSON({"repository" => @repo_ref})

    last_response.should be_ok
    created = JSON(last_response.body)

    known_warnings = ["accession_date", "accession_id_0", "condition_description", "content_description", "title"]

    (known_warnings - created["warnings"].keys).should eq([])
  end


  it "supports updates" do
    post "/accessions", params = JSONModel(:accession).
      from_hash({
                  "accession_id_0" => "1234",
                  "repository" => @repo_ref,
                  "title" => "The accession title",
                  "content_description" => "The accession description",
                  "condition_description" => "The condition description",
                  "accession_date" => "2012-05-03",
                }).to_json

    last_response.should be_ok
    created = JSON(last_response.body)


    # Update it
    post "/accessions/#{created['id']}", params = JSONModel(:accession).
      from_hash({
                  "repository" => @repo_ref,
                  "accession_id_0" => "1234",
                  "accession_id_1" => "5678",
                  "accession_id_2" => "1234",
                  "title" => "The accession title",
                  "content_description" => "The accession description",
                  "condition_description" => "The condition description",
                  "accession_date" => "2012-05-03",
                }).to_json


    get "/accessions/#{created['id']}"

    acc = JSON(last_response.body)

    acc["accession_id_1"].should eq("5678")
  end

end
