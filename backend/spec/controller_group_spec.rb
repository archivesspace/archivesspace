require 'spec_helper'

describe 'Group controller' do

  it "lets you create a group and get it back" do
    opts = {:description => generate(:generic_description)}
    group = create(:json_group, opts)
    expect(JSONModel(:group).find(group.id).description).to eq(opts[:description])
  end


  it "lets you set the group's membership" do
    group = create(:json_group)

    create(:user, {:username => 'herman'})
    create(:user, {:username => 'guybrush'})
    create(:user, {:username => 'elaine'})

    group.member_usernames = ["herman"]
    group.save

    expect(JSONModel(:group).find(group.id).member_usernames).to eq(["herman"])

    group.member_usernames = ["guybrush", "elaine"]
    group.save

    expect(JSONModel(:group).find(group.id).member_usernames.sort).to eq(["elaine", "guybrush"])
  end


  it "optionally leaves group members alone" do
    group = create(:json_group)

    create(:user, {:username => 'herman'})
    create(:user, {:username => 'guybrush'})
    create(:user, {:username => 'elaine'})

    group.member_usernames = ["herman"]
    group.save

    expect(JSONModel(:group).find(group.id).member_usernames).to eq(["herman"])

    group.member_usernames = ["guybrush", "elaine"]
    group.save(:with_members => false)

    # untouched
    expect(JSONModel(:group).find(group.id).member_usernames).to eq(["herman"])

    # And no members at all if we add that to our query
    expect(JSONModel(:group).find(group.id, :with_members => false).member_usernames.length).to eq(0)
  end


  it "assigns permissions" do
    group = create(:json_group)
    create(:user, {:username => 'guybrush'})

    Permission.define("swashbuckle", "The right to sail the high seas!")

    group.member_usernames = ["guybrush"]
    group.grants_permissions = ["swashbuckle"]
    group.save

    expect(User[:username => "guybrush"].can?("swashbuckle",
                                       :repo_id => $repo_id)).to be_truthy
  end


  it "restricts group listings to only the current repository" do
    repo_one = create(:repo, :repo_code => 'RepoOne')
    create(:json_group, {:group_code => "group-in-repo1"})

    repo_two = create(:repo, :repo_code => 'RepoTwo')
    create(:json_group, {:group_code => "group-in-repo2"})

    groups = JSONModel(:group).all({}, {:repo_id => repo_one.id})

    expect(groups.map(&:group_code).include?("group-in-repo2")).to be_falsey
  end


  it "stops you assigning a global permission to a repository" do
    group = create(:json_group)
    create(:user, {:username => 'guybrush'})

    Permission.define("captain", "The captain of the ArchivesSpace ship",
                      :level => "global")

    group.member_usernames = ["guybrush"]
    group.grants_permissions = ["captain"]

    expect { group.save }.to raise_error(AccessDeniedException)
  end


  it "restricts group-related activities to repository-managers" do
    create(:user, {:username => 'archivist'})
    archivists = JSONModel(:group).all(:group_code => "repository-archivists").first
    archivists.member_usernames = ["archivist"]
    archivists.save

    create(:user, {:username => 'viewer'})
    viewers = JSONModel(:group).all(:group_code => "repository-viewers").first
    viewers.member_usernames = ["viewer"]
    viewers.save

    ["archivist", "viewer"].each do |user|
      expect {
        as_test_user(user) do JSONModel(:group).all(:page => 1)['results'] end
      }.to raise_error(AccessDeniedException)

      expect {
        as_test_user(user) do JSONModel(:group).find(archivists.id) end
      }.to raise_error(AccessDeniedException)

      expect {
        as_test_user(user) do archivists.save end
      }.to raise_error(AccessDeniedException)
    end
  end


  it "gives a list of all groups" do

    group = create(:json_group, {:group_code => 'supergroup'})
    group = create(:json_group, {:group_code => 'groupthink'})
    group = create(:json_group, {:group_code => 'groupygroup'})

    groups = JSONModel(:group).all

    expect(groups.any? { |group| group.group_code == "supergroup" }).to be_truthy
    expect(groups.any? { |group| group.group_code == "groupthink" }).to be_truthy
    expect(groups.any? { |group| group.group_code == "groupygroup" }).to be_truthy
  end


  it "allows repository managers to view the group list" do
    create(:user, {:username => 'newmanager'})
    create(:user, {:username => 'underling'})

    managers = JSONModel(:group).all(:group_code => "repository-managers").first
    managers.member_usernames = ["newmanager"]
    managers.save

    expect {
      as_test_user("newmanager") do
        JSONModel(:group).all
      end
    }.not_to raise_error

    expect {
      as_test_user('underling') do
        JSONModel(:group).all
      end
    }.to raise_error(AccessDeniedException)
  end

end
