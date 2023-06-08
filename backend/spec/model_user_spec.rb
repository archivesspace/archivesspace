require 'spec_helper'

describe 'User model' do

  before(:each) do
    @repo_uri = create(:repo, :repo_code => 'ARCHIVESSPACE').uri

    agent_record = create(:json_agent_person)

    # @agent_opts = {:agent_record_id => JSONModel(:agent_person).id_for(agent_record.uri), :agent_record_type => :agent_person}
  end


  it "can yield a list of all permissions" do
    user = make_test_user("mark")

    [["testgroup-1", "create_repository"],
     ["testgroup-2", "manage_repository"],
     ["testgroup-3", "manage_repository"]].each do |group, permission|

      opts = {:group_code => group}

      group = Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)

      group.grant(permission)
      group.add_user(user)
    end

    expect(user.permissions[@repo_uri].sort).to eq(["create_repository", "manage_repository", "update_location_record"])
  end


  it "creates an Agent record for a new User created from a JSONModel" do

    json = build(:json_user)

    user = User.create_from_json(json)

    agent = AgentPerson.to_jsonmodel(user.agent_record_id)
    expect(agent.names[0]['primary_name']).to eq (user.name)
  end


  it "allows users to have the same name, but different usernames" do
    json_1 = build(:json_user, {:name => 'John Smith',
                                :username => 'jsmith1'})

    json_2 = build(:json_user, {:name => 'John Smith',
                                :username => 'jsmith2'})

    User.create_from_json(json_1)

    expect { User.create_from_json(json_2) }.not_to raise_error
  end


  it "remembers the uri of its agent record when converting into a JSONModel" do
    json = build(:json_user)
    user = User.create_from_json(json)
    agent = AgentPerson.to_jsonmodel(user.agent_record_id)
    json_user = User.to_jsonmodel(User.get_or_die(user.id), {})
    expect(json_user['agent_record']['ref']).to eq(agent.uri)
  end


  it "can assign a password to a user and authenticate that user" do
    password = generate(:alphanumstr)
    new_user = create(:user)

    DBAuth.set_password(new_user.username, password)

    expect(AuthenticationManager.authenticate(new_user.username, 'badpass')).to be_nil

    expect(AuthenticationManager.authenticate(new_user.username, password).username).to eq(new_user.username)
  end


  it "can update a user's password" do
    pass1 = generate(:alphanumstr)
    pass2 = generate(:alphanumstr)
    new_user = create(:user)
    expect(new_user.source).to eq("local")
    DBAuth.set_password(new_user.username, pass1)

    expect(AuthenticationManager.authenticate(new_user.username, pass1).username).to eq(new_user.username)

    DBAuth.set_password(new_user.username, pass2)

    expect(AuthenticationManager.authenticate(new_user.username, pass1)).to be_nil

    authed = AuthenticationManager.authenticate(new_user.username, pass2)
    expect(authed.username).to eq(new_user.username)
    expect(authed.source).to eq("DBAuth")
  end


  it "can add groups to a user" do
    group = Group.create_from_json(build(:json_group), :repo_id => $repo_id)

    new_user = create(:user)
    new_user.add_to_groups(group)

    expect(Group[group[:id]].user).to include(new_user)
  end


  it "notifies about ACL changes when new groups are added to a user" do

    group = Group.create_from_json(build(:json_group), :repo_id => $repo_id)
    new_user = create(:user)

    old_notification = Notifications.last_notification
    new_user.add_to_groups(group)

    expect(Notifications.last_notification).not_to eq(old_notification)
  end


  it "correctly applies derived permissions" do
    user = make_test_user("mark")

    repo_a = create(:repo, :repo_code => 'FIRST_REPO')
    repo_b = create(:repo, :repo_code => 'SECOND_REPO')

    # set the user as repo manager in repo A
    group = Group.create_from_json(build(:json_group, {:group_code => "testgroup-1"}), :repo_id => repo_a.id)
    group.grant("manage_repository")
    group.add_user(user)

    # set the user as archivist in repo B
    group = Group.create_from_json(build(:json_group, {:group_code => "testgroup-2"}), :repo_id => repo_b.id)
    group.grant("view_repository")
    group.add_user(user)

    expect(user.permissions[repo_a.uri].sort).to eq(["manage_repository", "update_location_record"])
    expect(user.permissions[repo_b.uri].sort).to eq(["update_location_record", "view_repository"])
    expect(user.permissions[Repository.GLOBAL].sort).to eq(["edit_user_self", "update_location_record"])
  end

  it "can delete a user even if it has preferences and import jobs" do

    group = Group.create_from_json(build(:json_group), :repo_id => $repo_id)
    new_user = create(:user)

    new_user.add_to_groups(group)

    json = build(:json_job,
                :job_type => 'import_job',
                :job => build(:json_import_job, :import_type => 'nonce'))


    Job.create_from_json(json, :repo_id => $repo_id, :user => new_user)

    RequestContext.open(:repo_id => Repository.global_repo_id) do
      Preference.create_from_json(build(:json_preference, :user_id => new_user.id))
    end

    new_user.delete

  end

  it "lets any user edit themself" do
    new_user = create(:user)
    expect(new_user.permissions[Repository.GLOBAL]).to include('edit_user_self')
  end
end
