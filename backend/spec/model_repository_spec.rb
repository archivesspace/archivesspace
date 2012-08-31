require 'spec_helper'

describe 'Repository model' do

  it "Supports creating a new repository" do
    repo = Repository.create(:repo_code => "TESTREPO",
                             :description => "My new test repository")

    repo = Repository.find(:repo_code => "TESTREPO")
    repo.description.should eq("My new test repository")
  end


  it "Enforces ID uniqueness" do
    expect { Repository.create(:repo_code => "TESTREPO",
                               :description => "My new test repository") }.to_not raise_error

    expect { Repository.create(:repo_code => "TESTREPO",
                               :description => "Another description") }.to raise_error
  end


  it "Enforces required fields" do

    expect { Repository.create(:description => "My new test repository") }.to raise_error

  end

end
