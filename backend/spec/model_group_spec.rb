require 'spec_helper'

describe 'Group model' do

  it "supports creating a new group" do
    opts = {:group_code => generate(:alphanumstr)}
    
    group = Group.create_from_json(
                              build(:json_group, opts), 
                              :repo_id => $repo_id)

    Group[group[:id]].group_code.should eq(opts[:group_code])
  end


  it "enforces group code uniqueness within a single repository" do
    
    opts = {:group_code => generate(:alphanumstr)}

    expect {
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
    }.to raise_error(Sequel::ValidationFailed)

    # No problems here
    expect {
      create(:repo)
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
    }.to_not raise_error
  end


  it "ignores case when checking group code uniqueness" do
    opts = {:group_code => generate(:alphanumstr).downcase} 
    Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)

    opts[:group_code].upcase!

    expect {
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "lets you add users to a group" do
    group = Group.create_from_json(build(:json_group), :repo_id => $repo_id)

    group.add_user(make_test_user("simon"))
    group.add_user(make_test_user("garfunkel"))

    group.user.map {|member| member[:username]}.sort.should eq(["garfunkel", "simon"])
  end


  it "lets you assign permissions to a group and apply them to users" do
    repo1 = create(:repo)
    repo2 = create(:repo)

    group = Group.create_from_json(build(:json_group), :repo_id => repo1.id)

    group.add_user(make_test_user("simon"))

    group.grant("manage_repository")

    group.permission.map {|permission| permission[:permission_code]}.should eq(["manage_repository"])

    RequestContext.put(:repo_id, repo1.id)
    User[:username => "simon"].can?("manage_repository").should eq(true)

    RequestContext.put(:repo_id, repo2.id)
    User[:username => "simon"].can?("manage_repository").should eq(false)
  end


  it "doesn't allow you to grant a non-existent permission" do
    repo1 = create(:repo)

    expect {
      group = Group.create_from_json(build(:json_group, :grants_permissions => ['fnoob_is_not_seriously_a_perm']), :repo_id => repo1.id)
    }.to raise_error(RuntimeError)
  end

end
