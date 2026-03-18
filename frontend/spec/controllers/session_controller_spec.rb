# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe SessionController, type: :controller do
  let(:repo) { create(:repo, repo_code: "session_test_#{SecureRandom.hex}") }
  let(:viewer) { create_user(repo => ['repository-viewers']) }
  let(:editor) { create_user(repo => ['repository-archivists']) }

  before(:each) do
    set_repo(repo)
  end

  describe '#check_session' do
    context 'CORS headers' do
      it 'sets Access-Control-Allow Origin and Credentials headers' do
        get :check_session, params: { uri: '/repositories/2/accessions/1' }

        aggregate_failures do
          expect(response.headers['Access-Control-Allow-Origin']).to eq(AppConfig[:public_proxy_url])
          expect(response.headers['Access-Control-Allow-Credentials']).to eq('true')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'returns can_access: false, mode: nil' do
        get :check_session, params: { uri: '/repositories/2/accessions/1' }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be false
        expect(json['mode']).to be_nil
      end
    end

    context 'when uri parameter is missing' do
      it 'returns can_access: false, mode: nil' do
        session = User.login('admin', 'admin')
        User.establish_session(controller, session, 'admin')
        controller.session[:repo_id] = JSONModel.repository

        get :check_session

        json = JSON.parse(response.body)
        expect(json['can_access']).to be false
        expect(json['mode']).to be_nil
      end
    end

    context 'when user has view-only permissions' do
      before(:each) do
        # Login as viewer and set up session
        session = User.login(viewer.username, viewer.password)
        User.establish_session(controller, session, viewer.username)
        controller.session[:repo_id] = JSONModel.repository
        controller.session[:repo] = repo.repo_code
      end

      it 'returns readonly mode for accession' do
        accession = create(:json_accession)

        get :check_session, params: { uri: accession.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end

      it 'returns readonly mode for resource' do
        resource = create(:resource)

        get :check_session, params: { uri: resource.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end

      it 'returns readonly mode for archival_object' do
        resource = create(:resource)
        archival_object = create(:archival_object,
                                 title: 'Test Archival Object',
                                 resource: { 'ref' => resource.uri })

        get :check_session, params: { uri: archival_object.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end

      it 'returns readonly mode for digital_object' do
        digital_object = create(:digital_object, title: 'Test Digital Object')

        get :check_session, params: { uri: digital_object.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end

      it 'returns readonly mode for digital_object_component' do
        digital_object = create(:digital_object, title: 'Test Digital Object')
        component = create(:digital_object_component,
                           title: 'Test Component',
                           digital_object: { 'ref' => digital_object.uri })

        get :check_session, params: { uri: component.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end

      it 'returns readonly mode for agent' do
        agent = create(:agent_person)

        get :check_session, params: { uri: agent.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end

      it 'returns readonly mode for subject' do
        subject = create(:subject)

        get :check_session, params: { uri: subject.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')
      end
    end

    context 'when user has edit permissions' do
      before(:each) do
        session = User.login(editor.username, editor.password)
        User.establish_session(controller, session, editor.username)
        controller.session[:repo_id] = JSONModel.repository
        controller.session[:repo] = repo.repo_code
      end

      it 'returns edit mode by default for accession' do
        accession = create(:json_accession)

        get :check_session, params: { uri: accession.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('edit')
      end

      it 'respects pui_staff_link_mode config when set to readonly' do
        accession = create(:json_accession)

        # Temporarily override config
        original_mode = AppConfig[:pui_staff_link_mode]
        AppConfig[:pui_staff_link_mode] = 'readonly'

        get :check_session, params: { uri: accession.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('readonly')

        # Restore original config
        AppConfig[:pui_staff_link_mode] = original_mode
      end

      it 'returns edit mode for resource' do
        resource = create(:resource)

        get :check_session, params: { uri: resource.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be true
        expect(json['mode']).to eq('edit')
      end
    end

    context 'when user has no permissions for the repository' do
      let(:other_repo) { create(:repo, repo_code: "other_repo_#{SecureRandom.hex}") }
      let(:other_user) { create_user(other_repo => ['repository-viewers']) }

      before(:each) do
        set_repo(repo)
        session = User.login(other_user.username, other_user.password)
        User.establish_session(controller, session, other_user.username)
      end

      it 'returns can_access: false, mode: nil' do
        accession = create(:json_accession)

        get :check_session, params: { uri: accession.uri }

        json = JSON.parse(response.body)
        expect(json['can_access']).to be false
        expect(json['mode']).to be_nil
      end
    end
  end
end
