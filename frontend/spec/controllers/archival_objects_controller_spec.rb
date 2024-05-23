# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ArchivalObjectsController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository
  end

  describe "New Archival Object" do
    let (:resource) { create(:json_resource) }
    let (:archival_object) { create(:json_archival_object,
                                    :resource => {'ref' => resource.uri}) }
    let (:random_archival_object) { create(:json_archival_object) }
    let (:accession) { create(:json_accession) }
    let(:default_values) {
      DefaultValues.new(
        JSONModel(:default_values).from_hash(
          {
            record_type: 'archival_object',
            defaults: {
              publish: true,
              title: 'Default Title'
            }
          })
      )
    }


    it "does not assign a resource to the new object by default" do
      get :new, params: { accession_id: accession.id }

      expect(response.status).to eq 200
      assert_select 'form input[id=archival_object_resource_]' do
        assert_select "[value=?]", ""
      end
    end

    it "can preset a resource using the :resource_id param" do
      get :new, params: { accession_id: accession.id,
                           resource_id: resource.id }

      expect(response.status).to eq 200
      assert_select 'form input[id=archival_object_resource_]' do
        assert_select "[value=?]", resource.uri
      end
    end

    it "can preset a parent archival object using the :archival_object_id param" do
      get :new, params: { accession_id: accession.id,
                           resource_id: resource.id,
                           archival_object_id: archival_object.id }

      expect(response.status).to eq 200
      assert_select 'form input[id=archival_object_parent_]' do
        assert_select "[value=?]", archival_object.uri
      end
    end

    it "can apply default values" do
      allow(controller).to receive(:user_defaults).with('archival_object').and_return(default_values)
      get :new, params: { resource_id: resource.id,
                          archival_object_id: archival_object.id }

      expect(response.status).to eq 200
      result = Capybara.string(response.body)
      result.find(:css, "#archival_object_title_") do |form_input|
        expect(form_input.value).to eq("Default Title")
      end
    end

    it "can spawn from an accession using the accession_id param, overriding defaults" do
      allow(controller).to receive(:user_defaults).with('archival_object').and_return(default_values)
      get :new, params: { accession_id: accession.id,
                          resource_id: resource.id,
                          archival_object_id: archival_object.id }

      expect(response.status).to eq 200
      result = Capybara.string(response.body)
      result.find(:css, "#archival_object_title_") do |form_input|
        expect(form_input.value).to eq(accession.title)
      end
    end

    it "can duplicate an archival object from another one using the duplicate_from_archival_object param" do
      get :new, params: { resource_id: resource.id,
                          duplicate_from_archival_object: { uri: archival_object.uri } }

      expect(response.status).to eq 200
      result = Capybara.string(response.body)

      result.find(:css, "#archival_object_title_") do |form_input|
        expect(form_input.value).to eq(archival_object.title)
      end
    end

    describe 'record title field' do
      before(:all) do
        @resource = create(:json_resource)
        @aobj = create(:json_archival_object, resource: {ref: @resource.uri})
      end

      before(:each) do
        allow(AppConfig).to receive(:[]).and_call_original
      end

      it 'does not support mixed content by default' do
        get :edit, params: {id: @aobj.id, inline: true}
        expect(response.body).to have_css('#archival_object_title_.form-control:not(.mixed-content)')
      end

      it 'supports mixed content when enabled' do
        allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
        get :edit, params: {id: @aobj.id, inline: true}
        expect(response.body).to have_css('#archival_object_title_.form-control.mixed-content')
      end
    end
  end
end
