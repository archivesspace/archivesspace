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
    it 'serves a known template with the ArchivesSpace version in the download name' do
      allow(ASConstants).to receive(:VERSION).and_return('v4.2.1')
      expect(controller).to receive(:send_file).with(
        "#{Rails.root}/public/bulk_import_templates/bulk_import_template.csv",
        filename: 'bulk_import_template_v4.2.1.csv',
        status: 202
      ) { controller.head :ok }
      get :download, params: { filename: 'bulk_import_template.csv' }
    end

    {
      'feature/foo' => 'bulk_import_template_feature-foo.xlsx',
      '-b7cc962' => 'bulk_import_template_b7cc962.xlsx',
      '-' => 'bulk_import_template.xlsx',
      '' => 'bulk_import_template.xlsx'
    }.each do |version, download_name|
      it "names the download #{download_name} when the version is #{version.inspect}" do
        allow(ASConstants).to receive(:VERSION).and_return(version)
        expect(controller).to receive(:send_file).with(
          "#{Rails.root}/public/bulk_import_templates/bulk_import_template.xlsx",
          filename: download_name,
          status: 202
        ) { controller.head :ok }
        get :download, params: { filename: 'bulk_import_template.xlsx' }
      end
    end

    it 'redirects to index for an unlisted filename' do
      get :download, params: { filename: 'evil.rb' }
      expect(response).to redirect_to(controller: :bulk_import_templates, action: :index)
    end
  end
end
