require 'spec_helper'

describe 'Accession controller' do

  it "lets you create an accession and get it back" do
    post '/repo', params = {
      "id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }


    post '/repo/ARCHIVESSPACE/accession', params = {
      :accession => JSON({
                           "accession_id_0" => "1234",
                           "accession_id_1" => "5678",
                           "accession_id_2" => "9876",
                           "accession_id_3" => "5432",
                           "title" => "The accession title",
                           "content_description" => "The accession description",
                           "condition_description" => "The condition description",
                           "accession_date" => "2012-05-03",
                         })
    }

    last_response.should be_ok


    get '/repo/ARCHIVESSPACE/accession/1234/5678/9876/5432'

    acc = JSON(last_response.body)

    acc["title"].should eq("The accession title")
  end


  it "works with partial IDs" do
    post '/repo', params = {
      "id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }


    post '/repo/ARCHIVESSPACE/accession', params = {
      :accession => JSONModel(:accession).from_hash({
                                                      "accession_id_0" => "1234",
                                                      "title" => "The accession title",
                                                      "content_description" => "The accession description",
                                                      "condition_description" => "The condition description",
                                                      "accession_date" => "2012-05-03",
                                                    }).to_json
    }

    last_response.should be_ok


    get '/repo/ARCHIVESSPACE/accession/1234'

    acc = JSON(last_response.body)

    acc["title"].should eq("The accession title")
  end

end
