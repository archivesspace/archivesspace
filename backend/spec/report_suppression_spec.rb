require 'spec_helper'

describe 'Report suppression filtering' do

  # A minimal concrete subclass for unit-testing AbstractReport directly
  let(:report_class) do
    Class.new(AbstractReport) do
      def query_string
        "select 1"
      end
    end
  end

  let(:base_params) { { repo_id: $repo_id, format: 'html' } }

  describe 'AbstractReport#suppressed_filter' do
    it 'returns a suppression clause when include_suppressed is not set' do
      report = DB.open { |db| report_class.new(base_params, nil, db) }
      expect(report.suppressed_filter('resource')).to eq(' AND resource.suppressed = 0')
    end

    it 'returns an empty string when include_suppressed is the boolean true' do
      report = DB.open { |db| report_class.new(base_params.merge('include_suppressed' => true), nil, db) }
      expect(report.suppressed_filter('resource')).to eq('')
    end

    it 'returns an empty string when include_suppressed is the string "true"' do
      report = DB.open { |db| report_class.new(base_params.merge('include_suppressed' => 'true'), nil, db) }
      expect(report.suppressed_filter('resource')).to eq('')
    end
  end

  describe 'AccessionReceiptReport' do
    before(:each) do
      @suppressed_accession = create_accession
      @suppressed_accession.set_suppressed(true)
    end

    it 'excludes suppressed accessions by default' do
      content = DB.open { |db| AccessionReceiptReport.new(base_params, nil, db).get_content }
      expect(content.map { |r| r[:record_title] }).not_to include(@suppressed_accession.title)
    end

    it 'includes suppressed accessions when include_suppressed is true' do
      params = base_params.merge('include_suppressed' => true)
      content = DB.open { |db| AccessionReceiptReport.new(params, nil, db).get_content }
      expect(content.map { |r| r[:record_title] }).to include(@suppressed_accession.title)
    end
  end

  describe 'ReportRunner permission enforcement' do
    it 'does not grant view_suppressed to a viewer-only user' do
      create_nobody_user
      user = User.find(:username => 'nobody')

      can_view = RequestContext.open(:repo_id => $repo_id) { user.can?(:view_suppressed) }
      expect(can_view).to be_falsey
    end

    it 'grants view_suppressed to a user with that permission' do
      make_test_user('suppression_reporter')
      group = create(:json_group)
      group.member_usernames = ['suppression_reporter']
      group.grants_permissions = ['view_suppressed', 'view_repository']
      group.save

      user = User.find(:username => 'suppression_reporter')

      can_view = RequestContext.open(:repo_id => $repo_id) { user.can?(:view_suppressed) }
      expect(can_view).to be_truthy
    end
  end

end
