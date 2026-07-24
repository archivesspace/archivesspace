require 'spec_helper'

describe 'Report suppression filtering' do
  let(:report_class) do
    Class.new(AbstractReport) do
      def query_string
        "select 1"
      end
    end
  end

  let(:report) { DB.open { |db| report_class.new(params, nil, db) } }

  describe 'AbstractReport#suppressed_filter' do
    context 'when include_suppressed is not provided' do
      let(:params) { { repo_id: $repo_id, format: 'html' } }

      it 'appends a suppression clause' do
        expect(report.suppressed_filter('resource')).to eq(' AND ifnull(resource.suppressed, 0) = 0')
      end
    end

    context 'when include_suppressed is the checked-checkbox value "1"' do
      let(:params) { { repo_id: $repo_id, format: 'html', 'include_suppressed' => '1' } }

      it 'returns an empty clause so suppressed rows are kept' do
        expect(report.suppressed_filter('resource')).to eq('')
      end
    end

    context 'when include_suppressed is the boolean true' do
      let(:params) { { repo_id: $repo_id, format: 'html', 'include_suppressed' => true } }

      it 'returns an empty clause so suppressed rows are kept' do
        expect(report.suppressed_filter('resource')).to eq('')
      end
    end

    context 'when include_suppressed is forced to false by the runner' do
      let(:params) { { repo_id: $repo_id, format: 'html', 'include_suppressed' => false } }

      it 'appends the suppression clause' do
        expect(report.suppressed_filter('resource')).to eq(' AND ifnull(resource.suppressed, 0) = 0')
      end
    end
  end

  describe 'end-to-end report filtering' do
    let!(:visible_accession) { create_accession(:title => 'Visible accession report record') }
    let!(:suppressed_accession) do
      accession = create_accession(:title => 'Suppressed accession report record')
      accession.set_suppressed(true)
      accession
    end

    def report_titles(extra_params = {})
      params = { repo_id: $repo_id, format: 'html' }.merge(extra_params)
      DB.open do |db|
        AccessionReport.new(params, nil, db).query.map { |row| row[:record_title] }
      end
    end

    it 'excludes suppressed accessions by default' do
      titles = report_titles
      expect(titles).to include(visible_accession.title)
      expect(titles).not_to include(suppressed_accession.title)
    end

    it 'includes suppressed accessions when include_suppressed is set' do
      titles = report_titles('include_suppressed' => '1')
      expect(titles).to include(visible_accession.title)
      expect(titles).to include(suppressed_accession.title)
    end
  end

  describe 'ReportRunner permission enforcement' do
    let(:can_view) { RequestContext.open(:repo_id => $repo_id) { user.can?(:view_suppressed) } }

    context 'when user is viewer only' do
      let(:user) do
        create_nobody_user
        User.find(:username => 'nobody')
      end

      it 'does not grant view_suppressed' do
        expect(can_view).to be_falsey
      end
    end

    context 'when user has view_suppressed permission' do
      let(:user) do
        make_test_user('suppression_reporter')
        group = create(:json_group)
        group.member_usernames = ['suppression_reporter']
        group.grants_permissions = ['view_suppressed', 'view_repository']
        group.save

        User.find(:username => 'suppression_reporter')
      end

      it 'grants view_suppressed' do
        expect(can_view).to be_truthy
      end
    end
  end
end
