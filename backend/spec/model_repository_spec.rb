require 'spec_helper'

describe 'Repository model' do

  it "Supports creating a new repository" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    repo = Repository.find(:repo_id => "TESTREPO")
    repo.description.should eq("My new test repository")
  end


  it "Enforces ID uniqueness" do
    Repository.create(:repo_id => "TESTREPO",
                      :description => "My new test repository")

    got_exception = false
    begin
      Repository.create(:repo_id => "TESTREPO",
                        :description => "Another description")
    rescue Sequel::DatabaseError => ex
      if DB.is_integrity_violation(ex)
        got_exception = true
      end
    end

    got_exception.should be_true
  end


  it "Enforces required fields" do
    got_exception = false

    begin
      Repository.create(:description => "My new test repository")
    rescue Sequel::DatabaseError => ex
      if DB.is_integrity_violation(ex)
        got_exception = true
      end
    end

    got_exception.should be_true
  end


  it "Allows accessions to be created" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    accession = repo.create_accession(JSONModel(:accession).
                                      from_hash({
                                                  "accession_id_0" => "1234",
                                                  "accession_id_1" => "5678",
                                                  "accession_id_2" => "9876",
                                                  "accession_id_3" => "5432",
                                                  "title" => "Papers of Mark Triggs",
                                                  "accession_date" => Time.now,
                                                  "content_description" => "Unintelligible letters written by Mark Triggs addressed to Santa Claus",
                                                  "condition_description" => "Most letters smeared with jam"
                                                }))

    Accession[accession].title.should eq("Papers of Mark Triggs")
  end


  it "Allows resources to be created" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    resource = repo.create_resource(:resource_id => "1234-5678-9876-5432",
                                    :title => "Mark Triggs collection",
                                    :level => "collection",
                                    :language => "ENG")

    res = repo.find_resource(:resource_id => resource.resource_id)

    res.title.should eq("Mark Triggs collection")
  end


end
