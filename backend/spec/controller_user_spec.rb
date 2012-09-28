require 'spec_helper'

def create_user
  user = JSONModel(:user).from_hash(:username => "test1",
                                    :name => "Tester")

  # Probably more realistic than we'd care to think
  user.save(:password => "password")
end


describe 'User controller' do

  before(:each) do
    create_user
  end

  it "rejects an unknown username" do
    post '/users/notauserXXXXXX/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.status.should eq(403)
  end


  it "expects a password" do
    post '/users/test1/login', params = {}
    last_response.should_not be_ok
    last_response.status.should eq(400)
  end


  it "rejects a bad password" do
    post '/users/test1/login', params = { "password" => "wrongpwXXXXX"}
    last_response.should_not be_ok
    last_response.status.should eq(403)
  end


  it "returns a session id if login is successful" do
    post '/users/test1/login', params = { "password" => "password"}
    last_response.should be_ok
    JSON(last_response.body)["session"].should match /^[0-9a-f]+$/
  end


  it "Treats the username as case insensitive" do
    post '/users/TEST1/login', params = { "password" => "password"}
    last_response.should be_ok
    last_response.status.should eq(200)
  end


  it "Rejects an invalid session" do
    get '/', params = {}, {"HTTP_X_ARCHIVESSPACE_SESSION" => "rubbish"}

    last_response.status.should eq(412)
    JSON(last_response.body)["code"].should eq ('SESSION_GONE')
  end


  it "Yields a list of the user's permissions" do
    make_test_repo

    group = JSONModel(:group).from_hash("group_code" => "newgroup",
                                        "description" => "A test group")
    group.grants_permissions = ["manage_repository"]
    group.member_usernames = ["test1"]
    id = group.save

    # as a part of the login process...
    post '/users/test1/login', params = { "password" => "password"}
    last_response.should be_ok
    JSON(last_response.body)["permissions"]["ARCHIVESSPACE"].should eq(["manage_repository"])

    # But also with the user
    user = JSONModel(:user).find('test1')
    user.permissions["ARCHIVESSPACE"].should eq(["manage_repository"])
  end

end
