# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe DigitalObjectsController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
  end

  describe 'record title field' do
    before(:each) do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository
      allow(AppConfig).to receive(:[]).and_call_original
    end

    it 'does not support mixed content by default' do
      get :new
      expect(response.body).to have_css('#digital_object_title_.form-control:not(.mixed-content)')
    end

    it 'supports mixed content when enabled' do
      allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
      get :new
      expect(response.body).to have_css('#digital_object_title_.form-control.mixed-content')
    end
  end

  describe 'spawning' do
    before(:each) do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository

      allow(AppConfig).to receive(:[]).and_call_original
      allow(controller).to receive(:user_prefs).and_return('digital_object_spawn' => true)
    end

    title_input_selector = 'textarea#digital_object_title_'

    it 'can create a digital object from a resource' do
      resource = create(:json_resource)
      fixture_dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'oai')
      resource.update(ASUtils.json_parse(File.read(File.join(fixture_dir, 'resource.json'))))
      resource.id_0 = "resource_#{Time.now}"
      resource.ead_id = "ead_#{Time.now}"
      resource.subjects = []
      resource.linked_events = []
      resource.linked_agents = []
      resource.save

      get :new, params: {spawn_from_resource_id: resource.id, inline: true}
      result = Capybara.string(response.body)
      result.find(:css, title_input_selector) do |input|
        expect(input.value).to eq('Resource 1')
      end
    end

    it 'can create a digital object from an accession' do
      acc_title = 'Accession title for spawn test'
      accession = create(:json_accession, :title => acc_title)
      get :new, params: {spawn_from_accession_id: accession.id, inline: true}
      result = Capybara.string(response.body)
      result.find(:css, title_input_selector) do |input|
        expect(input.value).to eq(acc_title)
      end
    end
  end
end
