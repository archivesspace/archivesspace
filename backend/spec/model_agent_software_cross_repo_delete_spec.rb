require 'spec_helper'

describe 'AgentSoftware cross-repository delete guard' do

  def link_agent_to_new_accession_in_repo(agent, repo)
    RequestContext.put(:repo_id, repo.id)
    create(:json_accession, 'linked_agents' => [{
                                                   'ref' => agent.uri,
                                                   'role' => 'source'
                                                 }])
  end


  it "blocks deletion by an ordinary (non-elevated) user when the agent is linked to a record in another repository" do
    repo_a = create(:repo)
    repo_b = create(:repo)

    RequestContext.put(:repo_id, repo_a.id)
    agent = AgentSoftware.create_from_json(build(:json_agent_software))

    link_agent_to_new_accession_in_repo(agent, repo_b)

    RequestContext.put(:repo_id, repo_a.id)

    group = Group.create_from_json(build(:json_group), :repo_id => repo_a.id)
    group.grant("manage_agent_record")

    user = make_test_user("ordinary_software_agent_deleter")
    group.add_user(user)

    as_test_user(user.username) do
      expect {
        AgentSoftware[agent[:id]].delete
      }.to raise_error(ConflictException)
    end
  end


  it "allows deletion when the agent has no links in another repository" do
    repo_a = create(:repo)

    RequestContext.put(:repo_id, repo_a.id)
    agent = AgentSoftware.create_from_json(build(:json_agent_software))

    expect {
      AgentSoftware[agent[:id]].delete
    }.not_to raise_error
  end


  it "allows deletion by a user with delete_agent_record_linked_elsewhere, even when linked elsewhere" do
    repo_a = create(:repo)
    repo_b = create(:repo)

    RequestContext.put(:repo_id, repo_a.id)
    agent = AgentSoftware.create_from_json(build(:json_agent_software))

    link_agent_to_new_accession_in_repo(agent, repo_b)

    RequestContext.put(:repo_id, repo_a.id)

    group = Group.create_from_json(build(:json_group), :repo_id => repo_a.id)
    group.grant("delete_agent_record_linked_elsewhere")

    user = make_test_user("elevated_software_agent_deleter")
    group.add_user(user)

    as_test_user(user.username) do
      expect {
        AgentSoftware[agent[:id]].delete
      }.not_to raise_error
    end
  end

end
