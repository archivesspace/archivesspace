require 'spec_helper'

describe 'Accession controller' do

  before(:each) do
    test_repo = {
      "repo_id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repo', params = { "repository" => JSONModel(:repository).from_hash(test_repo).to_json }
    @repo = JSON(last_response.body)["id"]
  end


  it "lets you create an accession and get it back" do
    post "/repo/#{@repo}/accession", params = {
      :accession => JSON({
                           "accession_id_0" => "1234",
                           "title" => "The accession title",
                           "content_description" => "The accession description",
                           "condition_description" => "The condition description",
                           "accession_date" => "2012-05-03",
                         })
    }

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/repo/#{@repo}/accession/#{created["id"]}"

    acc = JSON(last_response.body)

    acc["title"].should eq("The accession title")
  end


  it "works with partial IDs" do
    post "/repo/#{@repo}/accession", params = {
      :accession => JSONModel(:accession).from_hash({
                                                      "accession_id_0" => "1234",
                                                      "title" => "The accession title",
                                                      "content_description" => "The accession description",
                                                      "condition_description" => "The condition description",
                                                      "accession_date" => "2012-05-03",
                                                    }).to_json
    }

    last_response.should be_ok
    created = JSON(last_response.body)

    get "/repo/#{@repo}/accession/#{created['id']}"

    acc = JSON(last_response.body)

    acc["title"].should eq("The accession title")
  end

end
