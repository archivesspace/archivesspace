require 'spec_helper'

describe 'Repository controller' do

  it "gives a list of all repositories" do

    [0,1].each do |n|
      repo_code = create(:repo).repo_code

      repos = JSONModel(:repository).all

      repos.any? { |repo| repo.repo_code == repo_code }.should be_true
      repos.any? { |repo| repo.repo_code == generate(:repo_code) }.should be_false
    end
  end

  it "can get back a single repository" do
    repo = create(:repo)

    JSONModel(:repository).find(repo.id).repo_code.should eq(repo.repo_code)
  end


  it "doesn't allow regular non-admin users to create new repositories" do
    user = create(:user)

    as_test_user(user.username) do
      expect {
        create(:json_repo)
      }.to raise_error(AccessDeniedException)
    end
  end


  it "Creating a repository automatically creates the standard set of groups" do
    groups = JSONModel(:group).all(:page => 1)['results'].map {|group| group.group_code}

    groups.include?("repository-managers").should be_true
    groups.include?("repository-archivists").should be_true
    groups.include?("repository-viewers").should be_true
  end


end
