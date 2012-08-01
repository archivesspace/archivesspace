require 'spec_helper'

describe 'Repository model' do

  it "Supports creating a new repository" do
    repo = Repository.create(:repo_code => "TESTREPO",
                             :description => "My new test repository")

    repo = Repository.find(:repo_code => "TESTREPO")
    repo.description.should eq("My new test repository")
  end


  it "Enforces ID uniqueness" do
    Repository.create(:repo_code => "TESTREPO",
                      :description => "My new test repository")

    got_exception = false
    begin
      Repository.create(:repo_code => "TESTREPO",
                        :description => "Another description")
    rescue Sequel::DatabaseError => ex
      if DB.is_integrity_violation(ex)
        got_exception = true
      end
    rescue Sequel::ValidationFailed
      got_exception = true
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
    rescue Sequel::ValidationFailed
      got_exception = true
    end

    got_exception.should be_true
  end

end
