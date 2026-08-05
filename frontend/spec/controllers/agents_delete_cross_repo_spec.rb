require 'spec_helper'
require 'rails_helper'

describe AgentsController, type: :controller do
  render_views

  context 'when user has the manage_agent_record permission' do
    before(:each) do
      user = create_user($repo => ['repository-managers'])

      session = User.login(user.username, user.password)
      user_permissions = session['user']['permissions'][$repo.uri] || []

      expect(user_permissions).to include('manage_agent_record')
      expect(user_permissions).to_not include('delete_agent_record_linked_elsewhere')

      User.establish_session(controller, session, user.username)
      controller.session[:repo_id] = JSONModel.repository
    end

    it 'blocks agent deletion when the agent is linked in another repository' do
      set_repo($repo)
      agent = create(:json_agent_person)

      other_repo = create(:repo, :repo_code => "other_repo_#{Time.now.to_i}", publish: true)
      set_repo(other_repo)
      create(:json_accession, 'linked_agents' => [{
                                                     'ref' => agent.uri,
                                                     'role' => 'source'
                                                   }])
      set_repo($repo)

      delete :delete, params: { id: JSONModel(:agent_person).id_for(agent.uri), agent_type: 'agent_person' }

      expect(response).to redirect_to(controller: :agents, action: :show, id: JSONModel(:agent_person).id_for(agent.uri))
      expect(flash[:error]).to include(I18n.t('errors.linked_to_other_repo'))
    end

    it 'allows deletion when the agent is linked only within the current repository' do
      set_repo($repo)
      agent = create(:json_agent_person)

      create(:json_accession, 'linked_agents' => [{
                                                     'ref' => agent.uri,
                                                     'role' => 'source'
                                                   }])

      delete :delete, params: { id: JSONModel(:agent_person).id_for(agent.uri), agent_type: 'agent_person' }

      expect(flash[:success]).to eq(I18n.t('agent._frontend.messages.deleted'))
    end
  end

end
