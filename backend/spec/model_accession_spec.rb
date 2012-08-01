require 'spec_helper'

describe 'Accession model' do

  it "Allows accessions to be created" do
    repo = Repository.create(:repo_code => "TESTREPO",
                             :description => "My new test repository")

    accession = Accession.create_from_json(JSONModel(:accession).
                                           from_hash({
                                                       "accession_id_0" => "1234",
                                                       "accession_id_1" => "5678",
                                                       "accession_id_2" => "9876",
                                                       "accession_id_3" => "5432",
                                                       "repository" => "/repositories/#{repo[:id]}",
                                                       "title" => "Papers of Mark Triggs",
                                                       "accession_date" => Time.now,
                                                       "content_description" => "Unintelligible letters written by Mark Triggs addressed to Santa Claus",
                                                       "condition_description" => "Most letters smeared with jam"
                                                     }))

    Accession[accession[:id]].title.should eq("Papers of Mark Triggs")
  end


  it "Enforces ID uniqueness" do
    repo = Repository.create(:repo_code => "TESTREPO",
                             :description => "My new test repository")

    lambda {
      2.times do
        Accession.create_from_json(JSONModel(:accession).
                                   from_hash({
                                               "accession_id_0" => "1234",
                                               "accession_id_1" => "5678",
                                               "accession_id_2" => "9876",
                                               "accession_id_3" => "5432",
                                               "repository" => "/repositories/#{repo[:id]}",
                                               "title" => "Papers of Mark Triggs",
                                               "accession_date" => Time.now,
                                               "content_description" => "Unintelligible letters written by Mark Triggs addressed to Santa Claus",
                                               "condition_description" => "Most letters smeared with jam"
                                             }))
      end
    }.should raise_error(Sequel::ValidationFailed)
  end

end
