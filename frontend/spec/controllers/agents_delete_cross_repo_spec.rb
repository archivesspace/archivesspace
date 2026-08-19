require 'spec_helper'
require 'rails_helper'

describe AgentsController, type: :controller do
  render_views

  def login_as_agent_manager(permission)
    ensure_admin_backend_session

    user = build(:json_user).save(password: 'password123')
    user = User.find(user)

    create(:json_group,
           member_usernames: [user.username],
           grants_permissions: ['view_repository', permission])

    apply_session_to_controller(controller, user.username, 'password123')
  end

  context 'when user has the manage_agent_record permission' do
    before(:each) do
      login_as_agent_manager('manage_agent_record')
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
