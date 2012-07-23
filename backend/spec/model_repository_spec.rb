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


end
