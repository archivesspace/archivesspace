require 'spec_helper'
require 'rails_helper'

describe AgentsController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
    apply_session_to_controller(controller, 'admin', 'admin')
  end

  it "shows the 'Linked in Other Repos' badge when the agent is linked to a record in another repository" do
    agent = create(:json_agent_person)

    other_repo = create(:repo, :repo_code => "other_repo_#{Time.now.to_i}", publish: true)
    set_repo(other_repo)
    create(:json_accession, 'linked_agents' => [{
                                                   'ref' => agent.uri,
                                                   'role' => 'source'
                                                 }])
    set_repo($repo)

    get :show, params: { id: JSONModel(:agent_person).id_for(agent.uri), agent_type: 'agent_person' }

    expect(response.body).to include(I18n.t('agent._frontend.linked_in_other_repository.label'))
  end

  it 'does not show the badge when the agent has no links in another repository' do
    agent = create(:json_agent_person)

    get :show, params: { id: JSONModel(:agent_person).id_for(agent.uri), agent_type: 'agent_person' }

    expect(response.body).not_to include(I18n.t('agent._frontend.linked_in_other_repository.label'))
  end

  it 'does not show the badge when the agent is only linked to the current repository' do
    agent = create(:json_agent_person)

    create(:json_accession, 'linked_agents' => [{
                                                   'ref' => agent.uri,
                                                   'role' => 'source'
                                                 }])

    get :show, params: { id: JSONModel(:agent_person).id_for(agent.uri), agent_type: 'agent_person' }

    expect(response.body).not_to include(I18n.t('agent._frontend.linked_in_other_repository.label'))
  end

end
