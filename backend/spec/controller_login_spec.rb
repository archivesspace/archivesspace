require 'spec_helper'

describe 'Login controller' do

  it "expects a password" do
    post '/auth/user/admin/login', params = {}
    last_response.should_not be_ok
    last_response.body.should match /"error"/
  end

  it "reject a bad password" do
    post '/auth/user/admin/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.body.should match /"error"/
  end

  it "return a session id if login is successful" do
    post '/auth/user/admin/login', params = { "password" => "admin123"}
    last_response.should be_ok
    last_response.body.should match /\{"session":".+"\}/
  end

end
