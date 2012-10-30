require 'spec_helper'

describe 'User model' do

  before(:each) do
    create(:repo, :repo_code => 'ARCHIVESSPACE')
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

end
