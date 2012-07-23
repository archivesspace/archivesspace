require 'spec_helper'

describe 'Accession controller' do

  it "lets you create an accession and get it back" do
    post '/repo', params = {
      "id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }


    post '/repo/ARCHIVESSPACE/accession', params = {
      :accession => JSON({
                           "accession_id" => "1234-5678-9876-5432",
                           "title" => "The accession title",
                           "content_description" => "The accession description",
                           "condition_description" => "The condition description",
                           "accession_date" => "2012-05-03 13:51:34",
                         })
    }

    last_response.should be_ok


    get '/repo/ARCHIVESSPACE/accession/1234-5678-9876-5432'

    acc = JSON(last_response.body)

    acc["title"].should eq("The accession title")
  end

end
