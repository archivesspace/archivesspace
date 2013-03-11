require 'spec_helper'

describe 'User model' do

  before(:each) do
    create(:repo, :repo_code => 'ARCHIVESSPACE')
    
    agent_record = create(:json_agent_person)
    
    # @agent_opts = {:agent_record_id => JSONModel(:agent_person).id_for(agent_record.uri), :agent_record_type => :agent_person}
  end


  it "Can yield a list of all permissions" do
    user = make_test_user("mark")
  
    [["testgroup-1", "create_repository"],
     ["testgroup-2", "manage_repository"],
     ["testgroup-3", "manage_repository"]].each do |group, permission|
  
      opts = {:group_code => group}
  
      group = Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
  
      group.grant(permission)
      group.add_user(user)
    end
  
    user.permissions['ARCHIVESSPACE'].sort.should eq(["create_repository", "manage_repository"])
  end
  
  
  it "creates an Agent record for a new User created from a JSONModel" do
    
    json = build(:json_user)
    
    user = User.create_from_json(json)
    
    agent = AgentPerson.to_jsonmodel(user.agent_record_id)  
    agent.names[0]['primary_name'].should eq (user.name)
  
  end
  
  it "Can assign a password to a user and authenticate that user" do
    password = generate(:alphanumstr)
    new_user = create(:user)
    
    DBAuth.set_password(new_user.username, password)
    
    AuthenticationManager.authenticate(new_user.username, 'badpass').should be nil
    
    AuthenticationManager.authenticate(new_user.username, password).username.should eq(new_user.username)
  end
  
  it "Can update a user's password" do
    pass1 = generate(:alphanumstr)
    pass2 = generate(:alphanumstr)
    new_user = create(:user)
    
    DBAuth.set_password(new_user.username, pass1)
    
    AuthenticationManager.authenticate(new_user.username, pass1).username.should eq(new_user.username)
    
    DBAuth.set_password(new_user.username, pass2)
    
    AuthenticationManager.authenticate(new_user.username, pass1).should be nil
    
    AuthenticationManager.authenticate(new_user.username, pass2).username.should eq(new_user.username)
    
  end
  
  it "can add groups to a user" do
    group = Group.create_from_json(build(:json_group), :repo_id => $repo_id)
  
    new_user = create(:user)
    new_user.add_to_groups(group)
  
    Group[group[:id]].user.should include(new_user)
  end
end
