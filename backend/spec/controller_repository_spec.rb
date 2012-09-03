require 'spec_helper'

describe 'Repository controller' do

  it "gives a list of all repositories" do
    make_test_repo("ARCHIVESSPACE")
    make_test_repo("TEST")

    repos = JSONModel(:repository).all

    repos.any? { |repo| repo.repo_code == "ARCHIVESSPACE" }.should be_true
    repos.any? { |repo| repo.repo_code == "TEST" }.should be_true
  end

  it "can get back a single repository" do
    id = make_test_repo("ARCHIVESSPACE")

    JSONModel(:repository).find(id).repo_code.should eq("ARCHIVESSPACE")
  end


end
