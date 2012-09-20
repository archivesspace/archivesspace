require 'spec_helper'

describe 'Group controller' do

  before(:each) do
    make_test_repo
  end


  def create_group(opts = {})
    group = JSONModel(:group).from_hash("group_code" => "newgroup",
                                        "description" => "A test group")
    group.update(opts)
    group.save

    group
  end


  it "lets you create a group and get it back" do
    created = create_group
    JSONModel(:group).find(created.id).description.should eq("A test group")
  end


  it "lets you set the group's membership" do
    group = create_group

    make_test_user("herman")
    make_test_user("guybrush")
    make_test_user("elaine")

    group.member_usernames = ["herman"]
    group.save

    JSONModel(:group).find(group.id).member_usernames.should eq(["herman"])

    group.member_usernames = ["guybrush", "elaine"]
    group.save

    JSONModel(:group).find(group.id).member_usernames.sort.should eq(["elaine", "guybrush"])
  end


  it "Optionally leaves group members alone" do
    group = create_group

    make_test_user("herman")
    make_test_user("guybrush")
    make_test_user("elaine")

    group.member_usernames = ["herman"]
    group.save

    JSONModel(:group).find(group.id).member_usernames.should eq(["herman"])

    group.member_usernames = ["guybrush", "elaine"]
    group.save(:with_members => false)

    # untouched
    JSONModel(:group).find(group.id).member_usernames.should eq(["herman"])

    # And no members at all if we add that to our query
    JSONModel(:group).find(group.id, :with_members => false).member_usernames.should eq(nil)
  end


  it "Assigns permissions" do
    group = create_group
    make_test_user("guybrush")

    Permission.define(:permission_code => "swashbuckle",
                      :description => "The right to sail the high seas!")

    group.member_usernames = ["guybrush"]
    group.grants_permissions = ["swashbuckle"]
    group.save

    User[:username => "guybrush"].can?("swashbuckle", @repo_id).should eq(true)
  end

end
