require 'spec_helper'

describe 'User controller' do

  before(:each) do
    create_user
  end


  it "allows admin users to create new users" do
    expect {
      build(:json_user).save(:password => '123')
    }.not_to raise_error
  end


  it "reports an error when requesting a nonexistent user" do
    resp = get "/users/343439"
    expect(resp.status).to eq (404)
  end


  it "can give a list of users" do
    a_user = create(:user)
    users = JSONModel(:user).all(:page => 1)['results']

    expect(users.any? { |user| user.username == "admin" }).to be_truthy
    expect(users.any? { |user| user.username == "test1" }).to be_truthy
    expect(users.any? { |user| user.username == a_user.username }).to be_truthy
  end


  it "allows admin users to update existing usernames" do
    new_username = generate(:username)

    otheruser = build(:json_user)
    otheruser.save(:password => '123', :repo_id => nil)
    expect(otheruser.username).not_to eq(new_username)

    updated = build(:json_user, {:username => new_username})
    otheruser.update(updated.to_hash)
    expect(otheruser.username).to eq(new_username)
    otheruser.save(:password => '456', :repo_id => nil)
    user = JSONModel(:user).find(otheruser.id)
    expect(user.username).to eq(new_username)
  end


  it "allows usernames with hyphens" do
    user = build(:json_user, :username => "herman-toothrot")
    user.save(:password => '123')

    expect(user.username).to eq("herman-toothrot")
  end


  it "does allow anonymous users to create new users and hence become non-anonymous users" do
    expect {
      as_anonymous_user do
        build(:json_user).save(:password => '123')
      end
    }.not_to raise_error
  end


  it "rejects a login attempt against an unknown username" do
    post '/users/notauserXXXXXX/login', params = { "password" => "wrongpwXXXXX"}
    expect(last_response).not_to be_ok
    expect(last_response.status).to eq(403)
  end


  it "expects a password" do
    post '/users/test1/login', params = {}
    expect(last_response).not_to be_ok
    expect(last_response.status).to eq(400)
  end


  it "rejects a bad password" do
    post '/users/test1/login', params = { "password" => "wrongpwXXXXX"}
    expect(last_response).not_to be_ok
    expect(last_response.status).to eq(403)
  end


  it "returns a session id if login is successful" do
    post '/users/test1/login', params = { "password" => "password"}
    expect(last_response).to be_ok
    expect(JSON(last_response.body)["session"]).to match /^[0-9a-f]+$/
  end


  it "treats the username as case insensitive" do
    post '/users/TEST1/login', params = { "password" => "password"}
    expect(last_response).to be_ok
    expect(last_response.status).to eq(200)
  end


  it "rejects an invalid session" do
    get '/', params = {}, {"HTTP_X_ARCHIVESSPACE_SESSION" => "rubbish"}

    expect(last_response.status).to eq(412)
    expect(JSON(last_response.body)["code"]).to eq ('SESSION_GONE')
  end


  it "yields a list of the user's permissions" do
    repo = create(:repo)

    group = JSONModel(:group).from_hash("group_code" => "newgroup",
                                        "description" => "A test group")
    group.grants_permissions = ["transfer_repository"]
    group.member_usernames = ["test1"]
    id = group.save

    # as a part of the login process...
    post '/users/test1/login', params = { "password" => "password"}
    expect(last_response).to be_ok
    auth_response = JSON(last_response.body)
    expect(auth_response["user"]["permissions"][repo.uri]).to eq(["transfer_repository"])

    # But also with the user
    user = JSONModel(:user).find_by_uri(auth_response["user"]["uri"])
    expect(user.permissions[repo.uri]).to eq(["transfer_repository"])
  end


  it "allows admin users to create a user with a set of groups" do

    group_a = create(:json_group)
    group_b = create(:json_group)

    user = build(:json_user)
    user.save(:password => '123', "groups[]" => [group_a.uri, group_b.uri])

    expect(JSONModel(:group).find(group_a.id).member_usernames).to include(user.username)
    expect(JSONModel(:group).find(group_b.id).member_usernames).to include(user.username)

  end


  it "does not allow anonymous users to place themselves in groups" do

    group_a = create(:json_group)

    expect {
      as_anonymous_user do
        build(:json_user).save(:password => '123', "groups[]" => [group_a.uri])
      end
    }.to raise_error(AccessDeniedException)
  end


  it "throws an exception when a user is created with an invalid group" do
    expect {
      build(:json_user).save(:password => '123', "groups[]" => ["/repositories/0/groups/999999999"])
    }.to raise_error(RecordNotFound)

  end


  it "allows admin users to create other admin users" do
    user_id = build(:json_user, :is_admin => true).save('password' => '123')
    expect(User[:id => user_id].can?(:administer_system)).to be_truthy
  end


  it "doesn't let non-admins create admins" do
    as_anonymous_user do
      expect {
        user_id = build(:json_user, :is_admin => true).save('password' => '123')
      }.to raise_error(AccessDeniedException)
    end
  end


  it "can update an existing user" do
    user_id = build(:json_user, :is_admin => true).save('password' => '123')
    user = JSONModel(:user).find(user_id)

    user.is_admin = true
    user.name = "A New Name"
    user.save

    user = JSONModel(:user).find(user_id)
    expect(user.is_admin).to be_truthy
    expect(user.name).to eq("A New Name")
  end


  it "can log out a session" do
    post '/users/test1/login', params = { "password" => "password", "expiring" => "false" }
    expect(last_response).to be_ok

    session_headers = {"HTTP_X_ARCHIVESSPACE_SESSION" => JSON(last_response.body)["session"]}

    get '/', params = {}, session_headers
    expect(last_response).to be_ok

    # Now log it out
    post '/logout', params = {}, session_headers

    get '/', params = {}, session_headers
    expect(last_response.status).to eq(412)
  end


end
