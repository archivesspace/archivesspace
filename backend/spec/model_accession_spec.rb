require 'spec_helper'

describe 'Accession model' do

  it "Allows accessions to be created" do
    repo = Repository.create(:repo_code => "TESTREPO",
                             :description => "My new test repository")

    accession = Accession.create_from_json(JSONModel(:accession).
                                           from_hash({
                                                       "id_0" => "1234",
                                                       "id_1" => "5678",
                                                       "id_2" => "9876",
                                                       "id_3" => "5432",
                                                       "title" => "Papers of Mark Triggs",
                                                       "accession_date" => Time.now,
                                                       "content_description" => "Unintelligible letters written by Mark Triggs addressed to Santa Claus",
                                                       "condition_description" => "Most letters smeared with jam"
                                                     }),
                                           :repo_id => repo[:id])

    Accession[accession[:id]].title.should eq("Papers of Mark Triggs")
  end


  it "Enforces ID uniqueness" do
    repo = Repository.create(:repo_code => "TESTREPO",
                             :description => "My new test repository")

    lambda {
      2.times do
        Accession.create_from_json(JSONModel(:accession).
                                   from_hash({
                                               "id_0" => "1234",
                                               "id_1" => "5678",
                                               "id_2" => "9876",
                                               "id_3" => "5432",
                                               "title" => "Papers of Mark Triggs",
                                               "accession_date" => Time.now,
                                               "content_description" => "Unintelligible letters written by Mark Triggs addressed to Santa Claus",
                                               "condition_description" => "Most letters smeared with jam"
                                             }),
                                   :repo_id => repo[:id])
      end
    }.should raise_error(Sequel::ValidationFailed)
  end

end
