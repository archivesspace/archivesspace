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
    context 'when include_suppressed is not set' do
      let(:params) { { repo_id: $repo_id, format: 'html' } }

      it 'returns a suppression clause' do
        expect(report.suppressed_filter('resource')).to eq(' AND resource.suppressed = 0')
      end
    end

    context 'when include_suppressed is set to boolean true' do
      let(:params) { { repo_id: $repo_id, format: 'html', include_suppressed: true } }

      it 'returns an empty string when include_suppressed is the boolean true' do
        expect(report.suppressed_filter('resource')).to eq('')
      end
    end

    context 'when include_suppressed is set to the string "true"' do
      let(:params) { { repo_id: $repo_id, format: 'html', include_suppressed: 'true' } }

      it 'returns an empty string when include_suppressed is the string "true"' do
        expect(report.suppressed_filter('resource')).to eq('')
      end
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
