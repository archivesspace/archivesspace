require 'spec_helper'

describe 'Repository controller' do

  it "lets you create a repository" do
    post '/repo', params = {
      "id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    last_response.should be_ok
  end


  it "requires an ID when creating a repository" do
    post '/repo', params = {
      "description" => "A new ArchivesSpace repository"
    }

    last_response.status.should eq(400)
  end


  it "gives a list of all repositories" do
    post '/repo', params = {
      "id" => "ARCHIVESSPACE",
      "description" => "A new ArchivesSpace repository"
    }

    post '/repo', params = {
      "id" => "TEST",
      "description" => "A test repository"
    }

    get '/repo'

    last_response.should be_ok
    repos = JSON(last_response.body)

    repos.any? { |repo| repo["id"] == "ARCHIVESSPACE" }.should be_true
    repos.any? { |repo| repo["id"] == "TEST" }.should be_true
  end


  it "lets you create a repository with spaces" do
    post '/repo', params = {
      "id" => "REPO WITH SPACES",
      "description" => "A new ArchivesSpace repository"
    }

    last_response.should be_ok

    get '/repo'

    last_response.should be_ok
    repos = JSON(last_response.body)

    repos.any? { |repo| repo["id"] == "REPO WITH SPACES" }.should be_true
  end

end
