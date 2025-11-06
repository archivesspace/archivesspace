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

  def stub_http(response, path: nil, method: Net::HTTP::Post)
    mock_http = instance_double(Net::HTTP)
    mock_request = instance_double(method)
    allow(Net::HTTP).to receive(:new).and_call_original
    allow(Net::HTTP).to receive(:new).with(URI(backend_url).host, URI(backend_url).port).and_return(mock_http)
    allow(method).to receive(:new).and_call_original
    allow(method).to receive(:new).with(path || anything).and_return(mock_request) if path
    allow(mock_request).to receive(:set_form_data)
    allow(mock_request).to receive(:[]=)
    allow(mock_http).to receive(:request).and_return(response)
    [mock_http, mock_request]
  end

  describe 'GET #show' do
    it 'renders the login template' do
      get :show
      expect(response).to render_template('shared/login')
    end

    it 'does not require authentication' do
      get :show
      expect(response).not_to redirect_to('/login')
    end
  end

  describe 'POST #login' do
    context 'when credentials are valid and user has PUI access' do
      before { stub_http(successful_login_response) }

      it 'sets the session tokens' do
        post :login, params: { user_name: username, password: password }

        expect(controller.session[:session]).to eq(session_token)
        expect(controller.session[:username]).to eq(username)
        expect(controller.session[:pui_username]).to eq(username)
      end

      it 'redirects to root' do
        post :login, params: { user_name: username, password: password }
        expect(response).to redirect_to('/')
      end

      it 'sends pui: true to the backend' do
        mock_http = instance_double(Net::HTTP)
        mock_request = instance_double(Net::HTTP::Post)
        allow(Net::HTTP).to receive(:new).and_call_original
        allow(Net::HTTP).to receive(:new)
          .with(URI(backend_url).host, URI(backend_url).port)
          .and_return(mock_http)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_http).to receive(:request).and_return(successful_login_response)

        expect(mock_request).to receive(:set_form_data).with(
          hash_including(pui: true)
        )

        post :login, params: { user_name: username, password: password }
      end
    end

    context 'when user does not have PUI permission' do
      before { stub_http(forbidden_response) }

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
      before { stub_http(failed_response) }

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
        stub_http(instance_double(Net::HTTPResponse, code: '200', body: 'not json'))
      end

      it 'renders the login template with an error' do
        post :login, params: { user_name: username, password: password }
        expect(response).to render_template('shared/login')
        expect(flash.now[:error]).to include('Login failed')
      end
    end
  end

  describe 'POST #staff_handoff' do
    let(:current_user_response) do
      instance_double(Net::HTTPResponse,
        code: '200',
        body: { 'username' => username, 'is_pui_viewer' => true }.to_json
      )
    end

    let(:non_pui_user_response) do
      instance_double(Net::HTTPResponse,
        code: '200',
        body: { 'username' => username, 'is_pui_viewer' => false }.to_json
      )
    end

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
        before { stub_http(current_user_response, method: Net::HTTP::Get) }

        it 'sets the session and returns success' do
          post :staff_handoff, params: { session: session_token, username: username }

          expect(controller.session[:session]).to eq(session_token)
          expect(controller.session[:pui_username]).to eq(username)
          expect(JSON.parse(response.body)['success']).to be true
        end
      end

      context 'when the user does not have PUI access' do
        before { stub_http(non_pui_user_response, method: Net::HTTP::Get) }

        it 'returns 403 with success: false' do
          post :staff_handoff, params: { session: session_token, username: username }

          expect(response.status).to eq(403)
          expect(JSON.parse(response.body)['success']).to be false
        end
      end

      context 'when the backend request fails' do
        before { stub_http(forbidden_response, method: Net::HTTP::Get) }

        it 'returns 403 with success: false' do
          post :staff_handoff, params: { session: session_token, username: username }

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
        expect(Net::HTTP).not_to receive(:new)
          .with(URI(AppConfig[:backend_url]).host, URI(AppConfig[:backend_url]).port)
        delete :logout
      end
    end

    context 'when pui_require_authentication is enabled' do
      let(:mock_http) { instance_double(Net::HTTP) }
      let(:mock_request) { instance_double(Net::HTTP::Post) }
      let(:ok_response) { instance_double(Net::HTTPResponse, code: '200', body: '{}') }

      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
        allow(AppConfig).to receive(:has_key?).and_call_original
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_http).to receive(:request).and_return(ok_response)
      end

      context 'when frontend_proxy_url is set' do
        before do
          allow(AppConfig).to receive(:has_key?).with(:frontend_proxy_url).and_return(true)
          allow(AppConfig).to receive(:[]).with(:frontend_proxy_url).and_return('http://localhost:3000')
        end

        it 'notifies the frontend and backend, then resets session' do
          expect(mock_http).to receive(:request).twice

          delete :logout

          expect(controller.session[:pui_username]).to be_nil
          expect(response).to redirect_to('/')
        end
      end

      context 'when frontend_proxy_url is not set' do
        before do
          allow(AppConfig).to receive(:has_key?).with(:frontend_proxy_url).and_return(false)
        end

        it 'notifies only the backend, then resets session' do
          expect(mock_http).to receive(:request).once

          delete :logout

          expect(controller.session[:pui_username]).to be_nil
          expect(response).to redirect_to('/')
        end
      end
    end
  end

  describe 'POST #logout_staff_session' do
    context 'when pui_require_authentication is disabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(false)
      end

      it 'returns 403' do
        post :logout_staff_session
        expect(response.status).to eq(403)
      end
    end

    context 'when pui_require_authentication is enabled' do
      before do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
        controller.session[:pui_username] = username
      end

      it 'resets the session and returns success' do
        post :logout_staff_session

        expect(controller.session[:pui_username]).to be_nil
        expect(JSON.parse(response.body)['success']).to be true
      end
    end
  end
end
