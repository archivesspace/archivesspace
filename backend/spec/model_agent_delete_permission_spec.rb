require 'spec_helper'

describe 'delete_agent_record_linked_elsewhere permission' do

  it 'is defined at the global level' do
    permission = Permission[:permission_code => "delete_agent_record_linked_elsewhere"]

    expect(permission).not_to be_nil
    expect(permission.level).to eq("global")
  end


  it 'is granted to the administrators group automatically' do
    admins = Group.any_repo[:group_code => Group.ADMIN_GROUP_CODE]

    expect(admins.permission.map {|permission| permission[:permission_code]}).
      to include("delete_agent_record_linked_elsewhere")
  end


  it 'is not granted to an agent manager via manage_agent_record' do
    repo = create(:repo)

    group = Group.create_from_json(build(:json_group), :repo_id => repo.id)
    group.grant("manage_agent_record")

    user = make_test_user("agent_manager_permission_test")
    group.add_user(user)

    RequestContext.put(:repo_id, repo.id)

    expect(User[:username => user.username].can?("delete_agent_record")).to be_truthy
    expect(User[:username => user.username].can?("delete_agent_record_linked_elsewhere")).to be_falsey
  end

end
