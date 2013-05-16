require 'spec_helper'

describe 'Repository controller' do

  it "gives a list of all repositories" do
    [0,1].each do |n|
      repo_code = create(:repo).repo_code

      repos = JSONModel(:repository).all

      repos.any? { |repo| repo.repo_code == repo_code }.should be_true
      repos.any? { |repo| repo.repo_code == generate(:repo_code) }.should be_false
    end
  end


  it "supports creating a repository" do
    repo = create(:json_repo)

    JSONModel(:repository).find(repo.id).repo_code.should eq(repo.repo_code)
  end


  it "supports updating a repository" do
    repo = create(:json_repo)
    repo.name = "A new name"
    repo.save

    JSONModel(:repository).find(repo.id).name.should eq("A new name")
  end


  it "can get back a single repository" do
    repo = create(:repo)

    JSONModel(:repository).find(repo.id).repo_code.should eq(repo.repo_code)
  end


  it "doesn't allow regular non-admin users to create new repositories" do
    user = create(:user)

    as_test_user(user.username) do
      expect {
        create(:json_repo)
      }.to raise_error(AccessDeniedException)
    end
  end


  it "creating a repository automatically creates the standard set of groups" do
    groups = JSONModel(:group).all.map {|group| group.group_code}

    groups.include?("repository-managers").should be_true
    groups.include?("repository-archivists").should be_true
    groups.include?("repository-viewers").should be_true
  end


  context "project manager role" do
    let!(:user) do
      user = create(:user)
      pms = JSONModel(:group).all(:group_code => "repository-project-managers").first
      pms.member_usernames = [user.username]
      pms.save

      user.username
    end

    it "has no access to system configuration" do
      as_test_user(user) do
        expect {
          JSONModel(:enumeration).new('name' => 'hello', 'values' => ['world']).save
        }.to raise_error(AccessDeniedException)
      end
    end


    it "has read-only access to location records" do
      admin_user = User[:username => User.ADMIN_USERNAME]

      loc = create(:json_location)

      as_test_user(user) do
        # No problem requesting a location
        fetched_loc = JSONModel(:location).find(loc.id)

        fetched_loc.building.should eq(loc.building)

        # but update isn't allowed
        expect {
          fetched_loc.save
        }.to raise_error(AccessDeniedException)
      end
    end


    it "has normal access to archival records (accessions, resources, etc.)" do
      as_test_user(user) do
        acc = create(:json_accession)
        acc.title = "No problems here"
        acc.save
      end
    end


    it "has normal access to agents" do
      as_test_user(user) do
        agent = create(:json_agent_person)
        agent.names[0]['primary_name'] = "No problems here"
        agent.save
      end
    end


    it "has normal access to subjects" do
      as_test_user(user) do
        create(:json_subject)
      end
    end


    it "has normal access to events and can create linkages" do
      as_test_user(user) do
        test_agent = create(:json_agent_person)
        test_accession = create(:json_accession)

        create(:json_event,
               :linked_agents => [{
                                    'ref' => test_agent.uri,
                                    'role' => generate(:agent_role)
                                  }],
               :linked_records => [{
                                     'ref' => test_accession.uri,
                                     'role' => generate(:record_role)
                                   }])
      end
    end

  end

end
