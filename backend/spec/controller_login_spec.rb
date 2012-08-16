require 'spec_helper'

describe 'Login controller' do

  it "rejects an unknown username" do
    post '/auth/user/notauserXXXXXX/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.body.should match /"error"/
  end

  it "expects a password" do
    post '/auth/user/test1/login', params = {}
    last_response.should_not be_ok
    last_response.body.should match /"error"/
  end

  it "rejects a bad password" do
    post '/auth/user/test1/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.body.should match /"error"/
  end

  it "returns a session id if login is successful" do
    post '/auth/user/test1/login', params = { "password" => "test1_123"}
    last_response.should be_ok
    last_response.body.should match /\{"session":".+"\}/
  end

  it "Treats the username as case insensitive" do
    post '/auth/user/TEST1/login', params = { "password" => "test1_123"}
    last_response.should be_ok
    last_response.body.should match /\{"session":".+"\}/
  end

  it "Rejects an invalid session" do
    get '/', params = {}, {"HTTP_X_ARCHIVESSPACE_SESSION" => "rubbish"}

    last_response.status.should eq(412)
    JSON(last_response.body)["code"].should eq ('SESSION_GONE')
  end


end
