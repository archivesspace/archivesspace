require 'spec_helper'
require 'rails_helper'

describe PreferencesController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository
  end

  describe 'GET edit' do
    it 'redirects to welcome page when no repositories exist' do
      # Ensure no repositories exist
      allow(JSONModel::HTTP).to receive(:get_json).with("/repositories").and_return([])

      get :edit, params: { id: 0 }
      expect(response).to redirect_to(controller: :welcome, action: :index)
      expect(flash[:error]).to eq(I18n.t("preference._frontend.messages.no_access_to_preferences"))
    end

    it 'shows preferences page when repositories exist' do
      # Mock the existence of at least one repository
      allow(JSONModel::HTTP).to receive(:get_json).with("/repositories").and_return([{"uri" => "/repositories/1"}])

      get :edit, params: { id: 0 }
      expect(response).not_to redirect_to(controller: :welcome, action: :index)
      expect(response.status).to eq(200)
      expect(flash[:error]).to be_nil
    end
  end
end
