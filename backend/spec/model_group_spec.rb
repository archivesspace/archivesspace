require 'spec_helper'

describe 'Group model' do

  before(:each) do
    make_test_repo
  end


  def test_group(group_code = "newgroup", description = "A test group")
    JSONModel(:group).from_hash(:group_code => "newgroup",
                                :description => "A test group")
  end


  it "Supports creating a new group" do
    group = Group.create_from_json(test_group, :repo_id => @repo_id)

    Group[group[:id]].group_code.should eq("newgroup")
  end


  it "Enforces group code uniqueness within a single repository" do
    repo_one = make_test_repo("RepoOne")
    repo_two = make_test_repo("RepoTwo")

    obj = JSONModel(:group).from_hash(:group_code => "newgroup",
                                      :description => "A test group")

    expect {
      Group.create_from_json(test_group, :repo_id => repo_one)
      Group.create_from_json(test_group, :repo_id => repo_one)
    }.to raise_error

    # No problems here
    Group.create_from_json(test_group, :repo_id => repo_two)
  end


  it "Ignores case when checking group code uniqueness" do
    Group.create_from_json(test_group("newgroup"), :repo_id => @repo_id)

    expect {
      Group.create_from_json(test_group("NEWGROUP"), :repo_id => @repo_id)
    }.to raise_error
  end


  it "Lets you add users to a group" do
    group = Group.create_from_json(test_group, :repo_id => @repo_id)

    group.add_user(make_test_user("simon"))
    group.add_user(make_test_user("garfunkel"))

    group.users.map {|member| member[:username]}.sort.should eq(["garfunkel", "simon"])
  end


  it "Lets you assign permissions to a group and apply them to users" do
    repo_one = make_test_repo("RepoOne")
    repo_two = make_test_repo("RepoTwo")

    group = Group.create_from_json(test_group, :repo_id => repo_one)

    group.add_user(make_test_user("simon"))
    group.add_user(make_test_user("garfunkel"))

    group.grant("manage_repository")

    group.permissions.map {|permission| permission[:permission_code]}.should eq(["manage_repository"])

    User[:username => "simon"].can?("manage_repository", :repo_id => repo_one).should eq(true)
    User[:username => "simon"].can?("manage_repository", :repo_id => repo_two).should eq(false)
  end

end
