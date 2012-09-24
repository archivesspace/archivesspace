require 'spec_helper'

describe 'User model' do

  before(:each) do
    make_test_repo
  end


  it "Can yield a list of all permissions" do
    user = make_test_user("mark")

    [["testgroup-1", "create_repository"],
     ["testgroup-2", "manage_repository"],
     ["testgroup-3", "manage_repository"]].each do |group, permission|
      test_group = JSONModel(:group).from_hash(:group_code => group,
                                               :description => "A test group")

      group = Group.create_from_json(test_group, :repo_id => @repo_id)

      group.grant(permission)
      group.add_user(user)
    end

    user.permissions['ARCHIVESSPACE'].sort.should eq(["create_repository", "manage_repository"])
  end

end
