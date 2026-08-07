# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe SessionsController, type: :controller do
  let(:backend_url) { AppConfig[:backend_url] }
  let(:username) { 'test1' }
  let(:password) { 'password' }
  let(:session_token) { SecureRandom.hex(10) }

  let(:successful_login_response) do
    instance_double(Net::HTTPResponse,
      code: '200',
      body: { 'session' => session_token, 'user' => { 'username' => username } }.to_json
    )
  end

  let(:forbidden_response) do
    instance_double(Net::HTTPResponse, code: '403', body: '{"error": "forbidden"}')
  end

  let(:failed_response) do
    instance_double(Net::HTTPResponse, code: '401', body: '{"error": "invalid credentials"}')
  end

  def stub_post_form(response)
    allow(JSONModel::HTTP).to receive(:post_form).and_return(response)
  end

  describe 'GET #show' do
    context 'when pui_require_authentication is disabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(false)
      end

      it 'returns 403' do
        get :show
        expect(response.status).to eq(403)
      end
    end

    context 'when pui_require_authentication is enabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
      end

      it 'renders the shared/login view' do
        get :show
        expect(response).to render_template('shared/login')
      end

      it 'renders the minimal login layout, not the full application shell' do
        get :show
        expect(response).to render_template(layout: 'layouts/login')
      end

      it 'does not require authentication' do
        get :show
        expect(response).not_to redirect_to('/login')
      end

      context 'when the user already has a valid pui session' do
        before do
          allow(JSONModel::HTTP).to receive(:get_json).and_return({ 'is_pui_viewer' => true })
          controller.session[:session] = session_token
        end

        it 'redirects to root instead of re-rendering the login form' do
          get :show
          expect(response).to redirect_to('/')
        end
      end
    end
  end

  describe 'POST #login' do
    context 'when pui_require_authentication is disabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(false)
      end

      it 'returns 403' do
        post :login, params: { user_name: username, password: password }
        expect(response.status).to eq(403)
      end

      it 'does not contact the backend' do
        expect(JSONModel::HTTP).not_to receive(:post_form)
        post :login, params: { user_name: username, password: password }
      end
    end

    context 'when pui_require_authentication is enabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
      end

      context 'when credentials are valid and user has PUI access' do
        before { stub_post_form(successful_login_response) }

        it 'sets the session tokens' do
          post :login, params: { user_name: username, password: password }

          expect(controller.session[:session]).to eq(session_token)
          expect(controller.session[:pui_username]).to eq(username)
        end

        it 'redirects to root' do
          post :login, params: { user_name: username, password: password }
          expect(response).to redirect_to('/')
        end

        it 'sends pui: true to the backend' do
          expect(JSONModel::HTTP).to receive(:post_form)
            .with(anything, hash_including(:pui => true))
            .and_return(successful_login_response)

          post :login, params: { user_name: username, password: password }
        end
      end

      context 'when user does not have PUI permission' do
        before { stub_post_form(forbidden_response) }

        it 'renders the login template' do
          post :login, params: { user_name: username, password: password }
          expect(response).to render_template('shared/login')
        end

        it 'sets a permission error flash message' do
          post :login, params: { user_name: username, password: password }
          expect(flash.now[:error]).to include('does not have permission to view the PUI')
          expect(flash.now[:error]).to include(username)
        end
      end

      context 'when credentials are invalid' do
        before { stub_post_form(failed_response) }

        it 'renders the login template' do
          post :login, params: { user_name: username, password: password }
          expect(response).to render_template('shared/login')
        end

        it 'sets a generic error flash message' do
          post :login, params: { user_name: username, password: password }
          expect(flash.now[:error]).to include('Login failed')
        end
      end

      context 'when the backend returns unparseable JSON' do
        before do
          stub_post_form(instance_double(Net::HTTPResponse, code: '200', body: 'not json'))
        end

        it 'renders the login template with an error' do
          post :login, params: { user_name: username, password: password }
          expect(response).to render_template('shared/login')
          expect(flash.now[:error]).to include('Login failed')
        end
      end

      context 'when the backend is unreachable' do
        before do
          allow(JSONModel::HTTP).to receive(:post_form).and_raise(Errno::ECONNREFUSED)
        end

        it 'renders the login template with an error instead of raising' do
          expect { post :login, params: { user_name: username, password: password } }.not_to raise_error
          expect(response).to render_template('shared/login')
          expect(flash.now[:error]).to include('Login failed')
        end
      end
    end
  end

  describe 'POST #staff_handoff' do
    let(:current_user_data) { { 'username' => username, 'is_pui_viewer' => true } }
    let(:non_pui_user_data) { { 'username' => username, 'is_pui_viewer' => false } }

    context 'when pui_require_authentication is disabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(false)
      end

      it 'returns 403' do
        post :staff_handoff, params: { session: session_token, username: username }
        expect(response.status).to eq(403)
      end
    end

    context 'when pui_require_authentication is enabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
      end

      context 'when the staff session is valid and user has PUI access' do
        before { allow(JSONModel::HTTP).to receive(:get_json).and_return(current_user_data) }

        it 'sets the session and returns success' do
          post :staff_handoff, params: { session: session_token, username: username }

          expect(controller.session[:session]).to eq(session_token)
          expect(controller.session[:pui_username]).to eq(username)
          expect(JSON.parse(response.body)['success']).to be true
        end
      end

      context 'when the user does not have PUI access' do
        before { allow(JSONModel::HTTP).to receive(:get_json).and_return(non_pui_user_data) }

        it 'returns 403 with success: false' do
          post :staff_handoff, params: { session: session_token, username: username }

          expect(response.status).to eq(403)
          expect(JSON.parse(response.body)['success']).to be false
        end
      end

      context 'when the backend request fails' do
        before { allow(JSONModel::HTTP).to receive(:get_json).and_raise(AccessDeniedException.new) }

        it 'returns 403 with success: false' do
          post :staff_handoff, params: { session: session_token, username: username }

          expect(response.status).to eq(403)
          expect(JSON.parse(response.body)['success']).to be false
        end
      end

      context 'when the backend is unreachable' do
        before { allow(JSONModel::HTTP).to receive(:get_json).and_raise(Errno::ECONNREFUSED) }

        it 'returns 403 with success: false instead of raising' do
          expect {
            post :staff_handoff, params: { session: session_token, username: username }
          }.not_to raise_error

          expect(response.status).to eq(403)
          expect(JSON.parse(response.body)['success']).to be false
        end
      end
    end
  end

  describe 'DELETE #logout' do
    before do
      controller.session[:session] = session_token
      controller.session[:pui_username] = username
    end

    context 'when pui_require_authentication is disabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(false)
      end

      it 'resets the session and redirects to root' do
        delete :logout

        expect(controller.session[:pui_username]).to be_nil
        expect(response).to redirect_to('/')
      end

      it 'does not make any HTTP calls' do
        expect(JSONModel::HTTP).not_to receive(:post_form)
        delete :logout
      end
    end

    context 'when pui_require_authentication is enabled' do
      let(:ok_response) { instance_double(Net::HTTPResponse, code: '200', body: '{}') }

      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
        allow(JSONModel::HTTP).to receive(:post_form).and_return(ok_response)
      end

      it 'notifies the backend to expire the session, then resets the local session' do
        expect(JSONModel::HTTP).to receive(:post_form).once.and_return(ok_response)

        delete :logout

        expect(controller.session[:pui_username]).to be_nil
        expect(response).to redirect_to('/')
      end

      it 'does not raise when the backend is unreachable, and still resets the session' do
        allow(JSONModel::HTTP).to receive(:post_form).and_raise(Errno::ECONNREFUSED)

        expect { delete :logout }.not_to raise_error

        expect(controller.session[:pui_username]).to be_nil
        expect(response).to redirect_to('/')
      end
    end
  end
end
