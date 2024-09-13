require 'spec_helper'

describe 'Repository controller' do

  it "gives a list of all repositories" do
    [0, 1].each do |n|
      repo_code = create(:repo).repo_code

      repos = JSONModel(:repository).all

      expect(repos.any? { |repo| repo.repo_code == repo_code }).to be_truthy
      expect(repos.any? { |repo| repo.repo_code == generate(:repo_code) }).to be_falsey
    end
  end


  it "supports creating a repository" do
    repo = create(:json_repository)

    expect(JSONModel(:repository).find(repo.id).repo_code).to eq(repo.repo_code)
  end


  it "supports updating a repository" do
    repo = create(:json_repository)
    repo.name = "A new name"
    repo.save

    expect(JSONModel(:repository).find(repo.id).name).to eq("A new name")
  end


  it "can get back a single repository" do
    repo = create(:repo)

    expect(JSONModel(:repository).find(repo.id).repo_code).to eq(repo.repo_code)
  end


  it "doesn't allow regular non-admin users to create new repositories" do
    user = create(:user)

    as_test_user(user.username) do
      expect {
        create(:json_repository)
      }.to raise_error(AccessDeniedException)
    end
  end


  it "returns a 404 when a repository is not found" do
    ids = JSONModel(:repository).all.map {|r| r.id }.sort
    ids.unshift 0

    non_existing_id = ids.last + 1

    url = URI("#{JSONModel::HTTP.backend_url}/repositories/with_agent/#{non_existing_id}")
    request = Net::HTTP::Get.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)

    expect(response.code).to eq("404")

    url = URI("#{JSONModel::HTTP.backend_url}/repositories/#{non_existing_id}")
    request = Net::HTTP::Get.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)

    expect(response.code).to eq("404")
  end


  it "creating a repository automatically creates the standard set of groups" do
    groups = JSONModel(:group).all.map {|group| group.group_code}

    expect(groups.include?("repository-managers")).to be_truthy
    expect(groups.include?("repository-archivists")).to be_truthy
    expect(groups.include?("repository-viewers")).to be_truthy
  end


  context "project manager role" do
    let!(:user) do
      user = create(:user)
      pms = JSONModel(:group).all(:group_code => "repository-project-managers").first
      pms.member_usernames = [user.username]
      pms.save

      user.username
    end

    it "has access to system configuration" do
      as_test_user(user) do
        expect {
          JSONModel(:enumeration).new('name' => 'hello', 'values' => ['world']).save
        }.not_to raise_error
      end
    end


    it "has read-only access to location records" do
      admin_user = User[:username => User.ADMIN_USERNAME]

      loc = create(:json_location)

      as_test_user(user) do
        # No problem requesting a location
        fetched_loc = JSONModel(:location).find(loc.id)

        expect(fetched_loc.building).to eq(loc.building)

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

    it "has access to agent contact details" do
      as_test_user(user) do
        agent = create(:json_agent_corporate_entity)
        agent.agent_contacts[0]['name'] = "No problems here"
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


    it "can delete an empty repository and all of its groups" do
      repository_to_be_deleted = create(:json_repository, {:repo_code => "TARGET_REPO"})

      repository_to_be_deleted.delete

      expect(Repository[:id => repository_to_be_deleted.id]).to be_nil
      expect(Group.filter(:repo_id => repository_to_be_deleted.id).count).to be(0)
    end


    it "will not refuse to delete a repository with records" do
      repository_to_be_deleted = make_test_repo("TARGET_REPO")

      create(:json_accession)

      expect {
        JSONModel(:repository).find(repository_to_be_deleted).delete
      }.not_to raise_error

      expect(Repository[:id => repository_to_be_deleted]).to be_nil
    end

  end

  it "can change positions of two repositories" do
    repo1 = create(:json_repository)
    repo2 = create(:json_repository)

    repo1_original_position = JSONModel(:repository).find(repo1.id).position
    repo2_original_position = JSONModel(:repository).find(repo2.id).position

    expect(repo2_original_position).to eq (repo1_original_position + 1)

    response = JSON.parse( JSONModel::HTTP.post_form("#{repo1.uri}/position", :position => repo2_original_position ).body )
    expect(response["id"]).to eq(repo1.id)
    expect(response["status"]).to eq("Updated")

    expect(JSONModel(:repository).find(repo1.id).position).to eq repo2_original_position
    expect(JSONModel(:repository).find(repo2.id).position).to eq repo1_original_position
  end
end
