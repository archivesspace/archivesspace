require 'spec_helper'

describe 'agent current_repo_id validation' do
  def link_agent_to_new_accession_in_repo(agent, repo)
    JSONModel.set_repository(repo.id)
    RequestContext.put(:repo_id, repo.id)
    create(:json_accession, 'linked_agents' => [{
                                                   'ref' => agent.uri,
                                                   'role' => 'source'
                                                 }])
  end

  def delete_agent(agent, current_repo_id)
    url = URI("#{JSONModel::HTTP.backend_url}/agents/people/#{agent[:id]}" +
              "?current_repo_id=#{current_repo_id}")

    JSONModel::HTTP.delete_request(url)
  end

  before(:each) do
    @repo_a = create(:repo)
    @repo_b = create(:repo)

    group = Group.create_from_json(build(:json_group), :repo_id => @repo_a.id)
    group.grant("manage_agent_record")

    @user = make_test_user("agent_manager_in_repo_a")
    group.add_user(@user)

    @agent = AgentPerson.create_from_json(build(:json_agent_person))
  end

  it "ignores a current_repo_id naming a repository the user doesn't manage agents in" do
    link_agent_to_new_accession_in_repo(@agent, @repo_b)

    response = as_test_user(@user.username) do
      delete_agent(@agent, @repo_b.id)
    end

    expect(response.code).to eq('409')
    expect(AgentPerson[@agent[:id]]).not_to be_nil
  end

  it "honours a current_repo_id naming a repository the user does manage agents in" do
    link_agent_to_new_accession_in_repo(@agent, @repo_a)

    response = as_test_user(@user.username) do
      delete_agent(@agent, @repo_a.id)
    end

    expect(response.code).to eq('200')
    expect(AgentPerson[@agent[:id]]).to be_nil
  end

  it "doesn't let a forged current_repo_id clear the linked_in_other_repository flag" do
    link_agent_to_new_accession_in_repo(@agent, @repo_b)

    json = as_test_user(@user.username) do
      JSONModel::HTTP.get_json("/agents/people/#{@agent[:id]}",
                               'current_repo_id' => @repo_b.id)
    end

    expect(json['linked_in_other_repository']).to eq(true)
  end
end
