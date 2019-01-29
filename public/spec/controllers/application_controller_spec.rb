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
