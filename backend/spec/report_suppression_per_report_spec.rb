require 'spec_helper'

describe 'Report suppression filtering, per report type' do
  def report_titles(report_class, title_column, params = {})
    merged = { repo_id: $repo_id, format: 'html' }.merge(params)
    job = double('Job', write_output: nil)
    DB.open do |db|
      db.fetch(report_class.new(merged, job, db).query_string).map { |row| row[title_column] }
    end
  end

  let(:report_params) { {} }

  shared_examples 'a report that omits suppressed records by default' do
    it 'reports the record, hides it once suppressed, and reports it again when include_suppressed is set' do
      record, title = report_record

      expect(report_titles(report_class, title_column, report_params))
        .to include(title), "expected #{report_class} to report the record before it is suppressed"

      record.set_suppressed(true)

      expect(report_titles(report_class, title_column, report_params)).to_not include(title)
      expect(report_titles(report_class, title_column, report_params.merge('include_suppressed' => '1')))
        .to include(title)
    end
  end

  describe 'accession reports' do
    let(:title) { "Suppressible Accession #{SecureRandom.hex(6)}" }
    let(:accession) do
      Accession.create_from_json(
        build(:json_accession,
              title: title,
              inventory: "Inventory #{SecureRandom.hex(6)}",
              accession_date: '2020-06-15'),
        repo_id: $repo_id)
    end
    let(:report_record) { [accession, title] }
    let(:title_column) { :record_title }

    describe AccessionReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionReport }
      end
    end

    describe AccessionDeaccessionsListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionDeaccessionsListReport }
      end
    end

    describe AccessionInventoryReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionInventoryReport }
      end
    end

    describe AccessionReceiptReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionReceiptReport }
      end
    end

    describe AccessionRightsTransferredReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionRightsTransferredReport }
        let(:report_record) do
          create(:json_event,
                 event_type: 'copyright_transfer',
                 linked_records: [{ 'ref' => accession.uri, 'role' => 'source' }])
          [accession, title]
        end
      end
    end

    describe AccessionSubjectsNamesClassificationsListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionSubjectsNamesClassificationsListReport }
      end
    end

    describe AccessionUnprocessedReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { AccessionUnprocessedReport }
      end
    end

    describe CreatedAccessionsReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { CreatedAccessionsReport }
        let(:report_params) { { 'from' => '2000-01-01', 'to' => '2100-01-01' } }
      end
    end
  end

  describe 'resource reports' do
    let(:title) { "Suppressible Resource #{SecureRandom.hex(6)}" }
    let(:resource) do
      Resource.create_from_json(
        build(:json_resource, title: title, restrictions: true),
        repo_id: $repo_id)
    end
    let(:report_record) { [resource, title] }
    let(:title_column) { :record_title }

    describe ResourcesListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { ResourcesListReport }
      end
    end

    describe ResourceDeaccessionsListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { ResourceDeaccessionsListReport }
      end
    end

    describe ResourceInstancesListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { ResourceInstancesListReport }
      end
    end

    describe ResourceLocationsListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { ResourceLocationsListReport }
      end
    end

    describe ResourceRestrictionsListReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { ResourceRestrictionsListReport }
      end
    end
  end

  describe 'digital object reports' do
    let(:title) { "Suppressible Digital Object #{SecureRandom.hex(6)}" }
    let(:digital_object) do
      DigitalObject.create_from_json(
        build(:json_digital_object, title: title, file_versions: [build(:json_file_version)]),
        repo_id: $repo_id)
    end
    let(:report_record) { [digital_object, title] }

    describe DigitalObjectListTableReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { DigitalObjectListTableReport }
        let(:title_column) { :record_title }
      end
    end

    describe DigitalObjectFileVersionsReport do
      it_behaves_like 'a report that omits suppressed records by default' do
        let(:report_class) { DigitalObjectFileVersionsReport }
        let(:title_column) { :digital_object_title }
      end
    end
  end

  describe CustomReport do
    it_behaves_like 'a report that omits suppressed records by default' do
      let(:report_class) { CustomReport }
      let(:title_column) { :record_title }
      let(:title) { "Suppressible Custom Accession #{SecureRandom.hex(6)}" }
      let(:accession) do
        Accession.create_from_json(build(:json_accession, title: title), repo_id: $repo_id)
      end
      let(:report_record) { [accession, title] }
      let(:report_params) do
        template_data = {
          'custom_record_type' => 'accession',
          'fields' => { 'title' => { 'include' => '1' } }
        }
        template = JSONModel(:custom_report_template).from_hash(
          'name' => "Suppression accession template #{SecureRandom.hex(6)}",
          'limit' => 1000,
          'data' => template_data.to_json)
        { 'template' => CustomReportTemplate.create_from_json(template).id.to_s }
      end
    end
  end
end
