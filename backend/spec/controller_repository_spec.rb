require 'spec_helper'

describe 'Repository controller' do

  it "gives a list of all repositories" do
    make_test_repo("ARCHIVESSPACE")
    make_test_repo("TEST")

    get '/repositories'

    last_response.should be_ok
    repos = JSON(last_response.body)

    repos.any? { |repo| repo["repo_code"] == "ARCHIVESSPACE" }.should be_true
    repos.any? { |repo| repo["repo_code"] == "TEST" }.should be_true
  end
  
  it "should create a repository when given a post request" do
    post "/repositories", params = JSONModel(:repository).from_hash( {
      :repo_code => "ghghghgh",
      :description => "this repository"
      
    }).to_json
    
    last_response.should be_ok
    response = JSON(last_response.body)
    response["status"].should eq "Created"
  end

end
