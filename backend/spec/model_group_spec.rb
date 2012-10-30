require 'spec_helper'

describe 'Group model' do

  before(:each) do
    create(:repo)
  end
  

  it "Supports creating a new group" do
    opts = {:group_code => generate(:alphanumstr)}
    
    group = Group.create_from_json(
                              build(:json_group, opts), 
                              :repo_id => $repo_id)

    Group[group[:id]].group_code.should eq(opts[:group_code])
  end


  it "Enforces group code uniqueness within a single repository" do
    
    opts = {:group_code => generate(:alphanumstr)}

    expect {
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
    }.to raise_error

    # No problems here
    expect {
      create(:repo)
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
    }.to_not raise_error
  end


  it "Ignores case when checking group code uniqueness" do
    
    opts = {:group_code => generate(:alphanumstr).downcase} 
       
    Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)

    opts[:group_code].upcase!

    expect {
      Group.create_from_json(build(:json_group, opts), :repo_id => $repo_id)
    }.to raise_error
  end


  it "Lets you add users to a group" do
    group = Group.create_from_json(build(:json_group), :repo_id => $repo_id)

    group.add_user(make_test_user("simon"))
    group.add_user(make_test_user("garfunkel"))

    group.user.map {|member| member[:username]}.sort.should eq(["garfunkel", "simon"])
  end


  it "Lets you assign permissions to a group and apply them to users" do
    repo1 = create(:repo)
    repo2 = create(:repo)

    group = Group.create_from_json(build(:json_group), :repo_id => repo1.id)

    group.add_user(make_test_user("simon"))

    group.grant("manage_repository")

    group.permission.map {|permission| permission[:permission_code]}.should eq(["manage_repository"])

    User[:username => "simon"].can?("manage_repository", :repo_id => repo1.id).should eq(true)
    
    User[:username => "simon"].can?("manage_repository", :repo_id => repo2.id).should eq(false)
  end

end
