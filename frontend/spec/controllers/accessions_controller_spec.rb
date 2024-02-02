# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe AccessionsController, type: :controller do
  render_views

  describe 'record title field' do
    before(:each) do
      set_repo($repo)
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository
      allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
      allow(AppConfig).to receive(:[]).and_call_original
    end

    it 'does not support mixed content by default' do
      get :new
      expect(response.body).to have_css('#accession_title_.form-control:not(.mixed-content)')
    end

    it 'supports mixed content when enabled' do
      allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
      get :new
      expect(response.body).to have_css('#accession_title_.form-control.mixed-content')
    end
  end
end
