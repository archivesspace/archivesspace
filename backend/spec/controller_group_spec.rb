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
    JSONModel(:group).find(group.id, :with_members => false).member_usernames.length.should eq(0)
  end


  it "Assigns permissions" do
    group = create_group
    make_test_user("guybrush")

    Permission.define("swashbuckle", "The right to sail the high seas!")

    group.member_usernames = ["guybrush"]
    group.grants_permissions = ["swashbuckle"]
    group.save

    User[:username => "guybrush"].can?("swashbuckle",
                                       :repo_id => @repo_id).should eq(true)
  end


  it "Restricts group listings to only the current repository" do
    repo_one = make_test_repo("RepoOne")
    repo_two = make_test_repo("RepoTwo")

    JSONModel(:group).from_hash("group_code" => "group-in-repo1",
                                "description" => "A test group").save(:repo_id => repo_one)

    JSONModel(:group).from_hash("group_code" => "group-in-repo2",
                                "description" => "A test group").save(:repo_id => repo_two)

    groups = JSONModel(:group).all({}, :repo_id => repo_one)

    groups.map(&:group_code).include?("group-in-repo2").should be_false
  end


  it "Stops you assigning a global permission to a repository" do
    group = create_group
    make_test_user("guybrush")

    Permission.define("captain", "The captain of the ArchivesSpace ship",
                      :level => "global")

    group.member_usernames = ["guybrush"]
    group.grants_permissions = ["captain"]

    expect { group.save }.to raise_error(AccessDeniedException)
  end


  it "Restricts group-related activities to repository-managers" do
    make_test_user("archivist")
    archivists = JSONModel(:group).all(:group_code => "repository-archivists").first
    archivists.member_usernames = ["archivist"]
    archivists.save

    make_test_user("viewer")
    viewers = JSONModel(:group).all(:group_code => "repository-viewers").first
    viewers.member_usernames = ["viewer"]
    viewers.save

    ["archivist", "viewer"].each do |user|
      expect {
        as_test_user(user) do JSONModel(:group).all end
      }.to raise_error(AccessDeniedException)

      expect {
        as_test_user(user) do JSONModel(:group).find(archivists.id) end
      }.to raise_error(AccessDeniedException)

      expect {
        as_test_user(user) do archivists.save end
      }.to raise_error(AccessDeniedException)
    end
  end

end
