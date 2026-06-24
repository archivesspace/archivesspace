# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe BulkImportTemplatesController, type: :controller do
  before(:each) do
    set_repo($repo)
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository
  end

  describe '#download' do
    it 'serves a known template from public/bulk_import_templates' do
      expect(controller).to receive(:send_file).with(
        "#{Rails.root}/public/bulk_import_templates/bulk_import_template.csv",
        status: 202
      ) { controller.head :ok }
      get :download, params: { filename: 'bulk_import_template.csv' }
    end

    it 'redirects to index for an unlisted filename' do
      get :download, params: { filename: 'evil.rb' }
      expect(response).to redirect_to(controller: :bulk_import_templates, action: :index)
    end
  end
end
