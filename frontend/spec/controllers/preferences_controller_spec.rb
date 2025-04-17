require 'spec_helper'
require 'rails_helper'

describe PreferencesController, type: :controller do
  render_views

  describe 'GET edit' do
    context 'when no repositories exist' do
      before(:each) do
        session = User.login('admin', 'admin')
        User.establish_session(controller, session, 'admin')

        allow(JSONModel::HTTP).to receive(:get_json).and_call_original
        allow(JSONModel::HTTP).to receive(:get_json).with("/repositories").and_return([])
        allow(MemoryLeak::Resources).to receive(:get).and_call_original
        allow(MemoryLeak::Resources).to receive(:get).with(:repository).and_return(double(find_all: []))
      end

      it 'redirects to welcome page when no repositories exist' do
        get :edit, params: { id: 0 }
        expect(response).to redirect_to(controller: :welcome, action: :index)
        expect(flash[:error]).to eq(I18n.t("preference._frontend.messages.no_access_to_preferences"))
      end
    end

    context 'when repositories exist' do
      before(:each) do
        set_repo($repo)
        session = User.login('admin', 'admin')
        User.establish_session(controller, session, 'admin')
        controller.session[:repo_id] = JSONModel.repository
      end

      it 'shows preferences page' do
        get :edit, params: { id: $repo.id }
        expect(response).not_to redirect_to(controller: :welcome, action: :index)
        expect(response.status).to eq(200)
        expect(flash[:error]).to be_nil
      end
    end
  end
end
