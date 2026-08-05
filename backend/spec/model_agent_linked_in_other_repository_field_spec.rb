require 'spec_helper'

describe 'linked_in_other_repository JSONModel field' do

  def link_agent_to_new_accession_in_repo(agent, repo)
    RequestContext.put(:repo_id, repo.id)
    create(:json_accession, 'linked_agents' => [{
                                                   'ref' => agent.uri,
                                                   'role' => 'source'
                                                 }])
  end

  it 'is true when the agent is linked to a record in another repository' do
    repo_a = create(:repo)
    repo_b = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))

    link_agent_to_new_accession_in_repo(agent, repo_b)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]],
                                    :calculate_linked_in_other_repository => true,
                                    :current_repo_id => repo_a.id)
    expect(json.linked_in_other_repository).to eq(true)
  end

  it 'is false when the agent has no links in another repository' do
    repo_a = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]],
                                    :calculate_linked_in_other_repository => true,
                                    :current_repo_id => repo_a.id)
    expect(json.linked_in_other_repository).to eq(false)
  end

  it "is false when the agent is only linked within the viewer's repository" do
    repo_a = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))
    link_agent_to_new_accession_in_repo(agent, repo_a)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]],
                                    :calculate_linked_in_other_repository => true,
                                    :current_repo_id => repo_a.id)
    expect(json.linked_in_other_repository).to eq(false)
  end

  it 'does not reveal which repository the agent is linked in' do
    repo_a = create(:repo)
    repo_b = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))

    link_agent_to_new_accession_in_repo(agent, repo_b)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]],
                                    :calculate_linked_in_other_repository => true,
                                    :current_repo_id => repo_a.id)
    expect(json.used_within_repositories).to eq([])
  end

  it 'is omitted unless explicitly requested via calculate_linked_in_other_repository' do
    repo_a = create(:repo)
    repo_b = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))

    link_agent_to_new_accession_in_repo(agent, repo_b)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]], :current_repo_id => repo_a.id)
    expect(json.linked_in_other_repository).to be_nil
  end

  it "treats a single linked repository as 'other' when no current_repo_id is supplied" do
    repo_a = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))
    link_agent_to_new_accession_in_repo(agent, repo_a)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]], :calculate_linked_in_other_repository => true)
    expect(json.linked_in_other_repository).to eq(true)
  end

  it 'is true when linked to 2+ repositories, regardless of current_repo_id' do
    repo_a = create(:repo)
    repo_b = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))
    link_agent_to_new_accession_in_repo(agent, repo_a)
    link_agent_to_new_accession_in_repo(agent, repo_b)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]],
                                    :calculate_linked_in_other_repository => true,
                                    :current_repo_id => repo_a.id)
    expect(json.linked_in_other_repository).to eq(true)
  end

  it 'is true when linked to 2+ repositories even when no current_repo_id is supplied' do
    repo_a = create(:repo)
    repo_b = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))
    link_agent_to_new_accession_in_repo(agent, repo_a)
    link_agent_to_new_accession_in_repo(agent, repo_b)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]], :calculate_linked_in_other_repository => true)
    expect(json.linked_in_other_repository).to eq(true)
  end

  it 'computes correctly alongside calculate_linked_repositories' do
    repo_a = create(:repo)
    repo_b = create(:repo)

    agent = AgentPerson.create_from_json(build(:json_agent_person))

    link_agent_to_new_accession_in_repo(agent, repo_b)

    json = AgentPerson.to_jsonmodel(AgentPerson[agent[:id]],
                                    :calculate_linked_repositories => true,
                                    :calculate_linked_in_other_repository => true,
                                    :current_repo_id => repo_a.id)

    expect(json.linked_in_other_repository).to eq(true)
    expect(json.used_within_repositories).to eq([repo_b.uri])
  end

end
