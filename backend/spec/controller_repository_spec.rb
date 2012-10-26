require 'spec_helper'

describe 'Repository controller' do

  it "gives a list of all repositories" do
    create(:repo, :repo_code => 'ARCHIVESSPACE')
    create(:repo, :repo_code => 'TEST')

    repos = JSONModel(:repository).all

    repos.any? { |repo| repo.repo_code == "ARCHIVESSPACE" }.should be_true
    repos.any? { |repo| repo.repo_code == "TEST" }.should be_true
  end

  it "can get back a single repository" do
    id = create(:repo, :repo_code => 'ARCHIVESSPACE').id

    JSONModel(:repository).find(id).repo_code.should eq("ARCHIVESSPACE")
  end


  it "Only allows admins to create new repositories" do
    create(:user, :username => "regularjoe")

    as_test_user("regularjoe") do
      expect {
        repo = JSONModel(:repository).from_hash("repo_code" => "regularjoe-repo",
                                                "description" => "A new ArchivesSpace repository").save
      }.to raise_error(AccessDeniedException)
    end
  end


  it "Creating a repository automatically creates the standard set of groups" do
    create(:repo)

    groups = JSONModel(:group).all.map {|group| group.group_code}

    groups.include?("repository-managers").should be_true
    groups.include?("repository-archivists").should be_true
    groups.include?("repository-viewers").should be_true
  end


end
