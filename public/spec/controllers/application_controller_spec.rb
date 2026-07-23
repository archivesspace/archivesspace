require 'spec_helper'

# This spec tests the slug -> param resolving code in ApplicationController.
# There are describe blocks for multiple controllers in this file, as there are special cases for different controllers.

# class SlugQueryResponseMock
#   @type      = nil
#   @id        = nil
#   @repo_id   = nil
#
#   def initialize(id, table, repo_id = nil)
#     @id      = id
#     @table   = table
#     @repo_id = repo_id
#   end
#
#   def body
#     return {:id => @id, :table => @table, :repo_id => @repo_id}.to_json
#   end
# end

# tests for slug -> id resolution for global spec controllers, eg:
# Repositories, Agents, Subjects
# describe RepositoriesController, type: :controller do
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = false
#   end
#
#   it "should set params[:id] == params[:slug_or_id] if slug_or_id is an integer" do
#     response = get :show, params: {:slug_or_id => "1"}
#
#     expect(controller.params[:id]).to eq("1")
#   end
#
#   it "should query the backend for id if slug_or_id is alphanumeric" do
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=foobar&controller=repositories&action=show")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "foobar"}
#   end
#
#   it "should set id params based on response from backend" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(3, "repository") }
#
#     response = get :show, params: {:slug_or_id => "foobar"}
#     expect(controller.params[:id]).to eq(3)
#   end
# end

# describe SubjectsController, type: :controller do
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = false
#   end
#
#   it "should set params[:id] == params[:slug_or_id] if slug_or_id is an integer" do
#     response = get :show, params: {:slug_or_id => "1"}
#
#     expect(controller.params[:id]).to eq("1")
#   end
#
#   it "should query the backend for id if slug_or_id is alphanumeric" do
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=baz&controller=subjects&action=show")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "baz"}
#   end
#
#   it "should set id params based on response from backend" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(3, "repository") }
#
#     response = get :show, params: {:slug_or_id => "foobar"}
#     expect(controller.params[:id]).to eq(3)
#   end
# end

# describe AgentsController, type: :controller do
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = false
#   end
#
#   after(:all) do
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set params[:id] == params[:slug_or_id] if slug_or_id is an integer" do
#     response = get :show, params: {:slug_or_id => "1"}
#
#     expect(controller.params[:id]).to eq("1")
#   end
#
#   it "should query the backend for id if slug_or_id is alphanumeric" do
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=who&controller=agents&action=show")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "who"}
#   end
#
#   it "set param['eid'] = 'people' if the response from the backend indicates the agent is an agent_person" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(2, "agent_person") }
#
#     response = get :show, params: {:slug_or_id => "who"}
#     expect(controller.params[:id]).to eq(2)
#     expect(controller.params[:eid]).to eq("people")
#   end
#
#   it "set param['eid'] = 'families' if the response from the backend indicates the agent is an agent_family" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(1, "agent_family") }
#
#     response = get :show, params: {:slug_or_id => "fam"}
#     expect(controller.params[:id]).to eq(1)
#     expect(controller.params[:eid]).to eq("families")
#   end
#
#   it "set param['eid'] = 'corporate_entities' if the response from the backend indicates the agent is an agent_corporate_entity" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(4, "agent_corporate_entity") }
#
#     response = get :show, params: {:slug_or_id => "corp"}
#     expect(controller.params[:id]).to eq(4)
#     expect(controller.params[:eid]).to eq("corporate_entities")
#   end
#
#    it "set param['eid'] = 'software' if the response from the backend indicates the agent is agent_software" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(8, "agent_software") }
#
#     response = get :show, params: {:slug_or_id => "prog"}
#     expect(controller.params[:id]).to eq(8)
#     expect(controller.params[:eid]).to eq("software")
#   end
# end


# tests for slug -> id resolution for repo spec controllers, eg:
# Resources, Accessions, Classifications, Digital Objects

# describe AccessionsController, type: :controller do
#
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set id params == slug params if slug params are integers" do
#     response = get :show, params: {:slug_or_id => "1", :repo_slug => "4"}
#
#     expect(controller.params[:id]).to eq("1")
#     expect(controller.params[:rid]).to eq("4")
#   end
#
#   it "should query the backend for id and repo_id if slug_or_id is alphanumeric" do
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug_with_repo?slug=what&controller=accessions&action=show&repo_slug=vault")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "what", :repo_slug => "vault"}
#   end
#
#   it "should query the backend for id and repo_id if slug_or_id is alphanumeric (repo_name_disabled)" do
#     AppConfig[:repo_name_in_slugs] = false
#
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=what&controller=accessions&action=show")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "what"}
#
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set id params based on response from backend" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "accession", 5) }
#
#     response = get :show, params: {:slug_or_id => "foobar"}
#     expect(controller.params[:id]).to eq(6)
#     expect(controller.params[:rid]).to eq(5)
#   end
# end

# describe ResourcesController, type: :controller do
#
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set id params == slug params if slug params are integers" do
#     response = get :show, params: {:slug_or_id => "1", :repo_slug => "4"}
#
#     expect(controller.params[:id]).to eq("1")
#     expect(controller.params[:rid]).to eq("4")
#   end
#
#   it "should query the backend for id and repo_id if slug_or_id is alphanumeric" do
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug_with_repo?slug=what&controller=resources&action=show&repo_slug=vault")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "what", :repo_slug => "vault"}
#   end
#
#   it "should query the backend for id and repo_id if slug_or_id is alphanumeric (repo_name_disabled)" do
#     AppConfig[:repo_name_in_slugs] = false
#
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=what&controller=resources&action=show")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "what"}
#
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set id params based on response from backend" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "resource", 5) }
#
#     response = get :show, params: {:slug_or_id => "foobar"}
#     expect(controller.params[:id]).to eq(6)
#     expect(controller.params[:rid]).to eq(5)
#   end
# end

# describe ObjectsController, type: :controller do
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set id params == slug params if slug params are integers" do
#     response = get :show, params: {:slug_or_id => "1", :repo_slug => "4", :obj_type => "archival_objects"}
#
#     expect(controller.params[:id]).to eq("1")
#     expect(controller.params[:rid]).to eq("4")
#   end
#
#   it "should query the backend for id and repo_id if slug_or_id is alphanumeric" do
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug_with_repo?slug=what&controller=objects&action=show&repo_slug=vault")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "what", :repo_slug => "vault", :obj_type => "archival_objects"}
#   end
#
#   it "should query the backend for id and repo_id if slug_or_id is alphanumeric (repo_name_disabled)" do
#     AppConfig[:repo_name_in_slugs] = false
#
#     expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=what&controller=objects&action=show")
#     expect(HTTP).to receive(:get_response).with(expected_uri)
#
#     response = get :show, params: {:slug_or_id => "what", :obj_type => "archival_objects"}
#
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   it "should set id params based on response from backend for digital objects" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "digital_object", 5) }
#
#     response = get :show, params: {:slug_or_id => "foobar", :obj_type => "digital_objects"}
#     expect(controller.params[:id]).to eq(6)
#     expect(controller.params[:rid]).to eq(5)
#     expect(controller.params[:obj_type]).to eq("digital_objects")
#   end
#
#   it "should set id params based on response from backend for archival objects" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "archival_object", 5) }
#
#     response = get :show, params: {:slug_or_id => "foobar", :obj_type => "archival_objects"}
#     expect(controller.params[:id]).to eq(6)
#     expect(controller.params[:rid]).to eq(5)
#     expect(controller.params[:obj_type]).to eq("archival_objects")
#   end
#
#   it "should set id params based on response from backend for digital object components" do
#     allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "digital_object_components", 5) }
#
#     response = get :show, params: {:slug_or_id => "foobar", :obj_type => "digital_object_components"}
#     expect(controller.params[:id]).to eq(6)
#     expect(controller.params[:rid]).to eq(5)
#     expect(controller.params[:obj_type]).to eq("digital_object_components")
#   end
# end

# describe ClassificationsController, type: :controller do
#   before(:all) do
#     AppConfig[:repo_name_in_slugs] = true
#   end
#
#   describe "Classifications" do
#     it "should set id params == slug params if slug params are integers" do
#       response = get :show, params: {:slug_or_id => "1", :repo_slug => "4"}
#
#       expect(controller.params[:id]).to eq("1")
#       expect(controller.params[:rid]).to eq("4")
#     end
#
#     it "should query the backend for id and repo_id if slug_or_id is alphanumeric" do
#       expected_uri = URI(JSONModel::HTTP.backend_url + "/slug_with_repo?slug=what&controller=classifications&action=show&repo_slug=vault")
#       expect(HTTP).to receive(:get_response).with(expected_uri)
#
#       response = get :show, params: {:slug_or_id => "what", :repo_slug => "vault"}
#     end
#
#     it "should query the backend for id and repo_id if slug_or_id is alphanumeric (repo_name_disabled)" do
#       AppConfig[:repo_name_in_slugs] = false
#
#       expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=what&controller=classifications&action=show")
#       expect(HTTP).to receive(:get_response).with(expected_uri)
#
#       response = get :show, params: {:slug_or_id => "what"}
#
#       AppConfig[:repo_name_in_slugs] = true
#     end
#
#     it "should set id params based on response from backend" do
#       allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "classifications", 5) }
#
#       response = get :show, params: {:slug_or_id => "foobar"}
#       expect(controller.params[:id]).to eq(6)
#       expect(controller.params[:rid]).to eq(5)
#     end
#   end
#
#   describe "Classification terms" do
#     it "should set id params == slug params if slug params are integers" do
#       response = get :term, params: {:slug_or_id => "1", :repo_slug => "4"}
#
#       expect(controller.params[:id]).to eq("1")
#       expect(controller.params[:rid]).to eq("4")
#     end
#
#     it "should query the backend for id and repo_id if slug_or_id is alphanumeric" do
#       expected_uri = URI(JSONModel::HTTP.backend_url + "/slug_with_repo?slug=what&controller=classifications&action=term&repo_slug=vault")
#       expect(HTTP).to receive(:get_response).with(expected_uri)
#
#       response = get :term, params: {:slug_or_id => "what", :repo_slug => "vault"}
#     end
#
#     it "should query the backend for id and repo_id if slug_or_id is alphanumeric (repo_name_disabled)" do
#       AppConfig[:repo_name_in_slugs] = false
#
#       expected_uri = URI(JSONModel::HTTP.backend_url + "/slug?slug=what&controller=classifications&action=term")
#       expect(HTTP).to receive(:get_response).with(expected_uri)
#
#       response = get :term, params: {:slug_or_id => "what"}
#
#       AppConfig[:repo_name_in_slugs] = true
#     end
#
#     it "should set id params based on response from backend" do
#       allow(HTTP).to receive(:get_response) { SlugQueryResponseMock.new(6, "classification_terms", 5) }
#
#       response = get :term, params: {:slug_or_id => "foobar"}
#       expect(controller.params[:id]).to eq(6)
#       expect(controller.params[:rid]).to eq(5)
#     end
#   end
# end

def stub_current_user_response(response)
  allow(JSONModel::HTTP).to receive(:get_response).and_return(response)
end

describe WelcomeController, type: :controller do
  context 'when pui_require_authentication is disabled' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(false)
    end

    it 'renders the real page with no session' do
      get :show
      expect(response).to have_http_status(200)
      expect(response).not_to render_template('shared/login')
    end
  end

  context 'when pui_require_authentication is enabled' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
    end

    it 'renders the login screen in place when there is no session' do
      get :show

      expect(response).to have_http_status(:unauthorized)
      expect(response).to render_template('shared/login')
      expect(response).to render_template(layout: 'layouts/login')
    end

    it 'passes through to the real page when the backend confirms a pui viewer session' do
      stub_current_user_response(instance_double(Net::HTTPResponse, code: '200', body: { 'is_pui_viewer' => true }.to_json))
      session[:session] = 'abc123'

      get :show

      expect(response).to have_http_status(200)
      expect(response).not_to render_template('shared/login')
    end

    it 'renders the login screen with a permission-denied flash for a valid session without pui access' do
      stub_current_user_response(instance_double(Net::HTTPResponse, code: '200', body: { 'username' => 'someuser', 'is_pui_viewer' => false }.to_json))
      session[:session] = 'abc123'
      session[:pui_username] = 'someuser'

      get :show

      expect(response).to render_template('shared/login')
      expect(flash.now[:error]).to include('does not have permission to view the PUI')
    end

    it 'shows the current session user in the permission-denied flash, not a stale one' do
      stub_current_user_response(instance_double(Net::HTTPResponse, code: '200', body: { 'username' => 'newuser', 'is_pui_viewer' => false }.to_json))
      session[:session] = 'abc123'
      session[:pui_username] = 'originaladminuser'

      get :show

      expect(response).to render_template('shared/login')
      expect(flash.now[:error]).to include('newuser')
      expect(flash.now[:error]).not_to include('originaladminuser')
    end

    it 'renders the login screen when the backend rejects the session' do
      stub_current_user_response(instance_double(Net::HTTPResponse, code: '412', body: '{}'))
      session[:session] = 'expired'

      get :show

      expect(response).to render_template('shared/login')
    end
  end
end

describe ResourcesController, type: :controller do
  context 'when pui_require_authentication is enabled and there is no session' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
    end

    it 'returns a JSON 401 instead of the HTML login page for JSON-only actions' do
      get :waypoints, params: { rid: 2, id: 1, urls: [] }

      expect(response).to have_http_status(:unauthorized)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)['error']).to eq('authentication_required')
    end
  end
end
