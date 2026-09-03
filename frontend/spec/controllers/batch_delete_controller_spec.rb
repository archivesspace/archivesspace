require 'spec_helper'
require 'rails_helper'

describe BatchDeleteController, type: :controller do
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

    it 'bulk-deletes an agent linked only within the current repository' do
      set_repo($repo)
      agent = create(:json_agent_person)

      create(:json_accession, 'linked_agents' => [{
                                                     'ref' => agent.uri,
                                                     'role' => 'source'
                                                   }])

      request.env['HTTP_REFERER'] = '/agents'
      post :agents, params: { record_uris: [agent.uri] }

      expect(flash[:success]).to eq(I18n.t('batch_delete.agents.success'))

      expect {
        JSONModel(:agent_person).find(JSONModel(:agent_person).id_for(agent.uri))
      }.to raise_error(RecordNotFound)
    end

    it "blocks bulk deletion of an agent linked in another repository" do
      set_repo($repo)
      agent = create(:json_agent_person)

      other_repo = create(:repo, :repo_code => "other_repo_#{Time.now.to_i}", publish: true)
      set_repo(other_repo)
      create(:json_accession, 'linked_agents' => [{
                                                     'ref' => agent.uri,
                                                     'role' => 'source'
                                                   }])
      set_repo($repo)

      request.env['HTTP_REFERER'] = '/agents'
      post :agents, params: { record_uris: [agent.uri] }

      expect(flash[:error]).to include(I18n.t('errors.linked_to_other_repo'))

      expect(JSONModel(:agent_person).find(JSONModel(:agent_person).id_for(agent.uri)).uri).to eq(agent.uri)
    end
  end
end
