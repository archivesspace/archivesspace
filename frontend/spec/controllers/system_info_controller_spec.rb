# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe SystemInfoController, type: :controller do
  render_views

  before(:each) do
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
  end

  describe 'show system info action' do
    before(:each) do
      allow(JSONModel::HTTP).to receive(:get_json).and_call_original
    end

    context "with app_context: 'backend_info' param" do
      it 'fetches the system info from the backend' do
        get :show, params: { app_context: 'backend_info' }

        expect(JSONModel::HTTP).to have_received(:get_json).with('/system/info')
        expect(response.status).to eq(200)
        expect(response.body).to include 'APPCONFIG'
        expect(response.body).to include 'DB_INFO'
        expect(response.body).to include 'SOLR_INFO'
        expect(response.body).to include 'Backend System Information'
      end
    end

    context "with app_context: 'frontend_info' param" do
      it 'fetches the system info from the frontend' do
        get :show, params: { app_context: 'frontend_info' }

        expect(JSONModel::HTTP).not_to have_received(:get_json).with('/system/info')
        expect(response.status).to eq(200)
        expect(response.body).to include 'APPCONFIG'
        expect(response.body).not_to include 'DB_INFO'
        expect(response.body).not_to include 'SOLR_INFO'
        expect(response.body).to include 'Frontend System Information'
      end
    end
  end

  describe 'show system log action' do
    context "with app_context: 'backend_log' param" do
      it 'fetches the system log from the backend' do
        get :show_log, params: { app_context: 'backend_log' }

        expect(response.status).to eq(200)
        expect(response.body).to include 'Backend Log'
      end
    end

    context "with app_context: 'frontend_log' param" do
      it 'fetches the system log from the frontend' do
        get :show_log, params: { app_context: 'frontend_log' }
        expect(response.status).to eq(200)
        expect(response.body).to include 'Frontend Log'
      end
    end
  end

  describe 'stream log action' do
    before(:each) do
      allow(JSONModel::HTTP).to receive(:get_response).and_call_original
    end

    context "with app_context: 'backend_log' param" do
      it 'fetches the system log from the backend' do
        get :stream_log, params: { app_context: 'backend_log' }

        expect(response.status).to eq(200)
        expect(JSONModel::HTTP).to have_received(:get_response).with(URI.parse(AppConfig[:backend_url] + "/system/log"))
      end
    end

    context "with app_context: 'frontend_log' param" do
      it 'fetches the system log from the frontend' do
        get :stream_log, params: { app_context: 'frontend_log' }

        expect(response.status).to eq(200)
        expect(JSONModel::HTTP).not_to have_received(:get_response).with(URI.parse(AppConfig[:backend_url] + "/system/log"))
      end
    end
  end
end
