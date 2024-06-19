require_relative 'spec_helper'

describe 'Bulk Updater model' do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_updater")
  let(:test_file) { BULK_FIXTURES_DIR + "/test_sheet.xlsx" }
  let(:test_file_with_errors) { BULK_FIXTURES_DIR + "/test_sheet_with_errors.xlsx" }
  let(:test_file_with_top_containers) { BULK_FIXTURES_DIR + "/test_file_with_top_containers.xlsx" }
  let(:test_file_with_new_top_containers) { BULK_FIXTURES_DIR + "/test_file_with_new_top_containers.xlsx" }

  let(:dates) { [build(:json_date)] }
  let(:notes) { [build(:json_note_singlepart), build(:json_note_multipart)] }
  let(:extents) { [build(:json_extent, {:portion => generate(:portion)})] }
  let(:accession) { create(:json_accession) }
  let(:lang_materials) { [build(:json_lang_material_with_note)] }
  let(:resource) { create(:json_resource,
                          :extents => extents,
                          :dates => dates,
                          :notes => notes,
                          :lang_materials => lang_materials,
                          :related_accessions => [{'ref' => accession.uri}]) }
  let(:location) { create(:json_location, :temporary => generate(:temporary_location_type)) }
  let(:top_container) { create(:json_top_container,
                              :container_locations => [{'ref' => location.uri,
                              'status' => 'current',
                              'start_date' => generate(:yyyy_mm_dd),
                              'end_date' => generate(:yyyy_mm_dd)}]) }
  let(:instances) { [build(:json_instance,
                          :sub_container => build(:json_sub_container,
                          :top_container => {:ref => top_container.uri}))] }

  let(:ao) { create(:json_archival_object, :resource => {:ref => resource.uri}, :dates => dates, :notes => notes, :instances => instances) }
  let(:min_subrecords) { 4 }
  let(:extra_subrecords) { 3 }
  let(:min_notes) { 2 }
  let(:selected_columns) { ["level", "component_id", "ref_id", "repository_processing_note", "publish", "date", "extent", "instance", "digital_object", "related_accession", "langmaterial", "note_abstract", "note_accruals", "note_bioghist", "note_accessrestrict", "note_dimensions", "note_altformavail", "note_odd", "note_phystech", "note_physdesc", "note_processinfo", "note_relatedmaterial", "note_scopecontent", "note_separatedmaterial"] }

  let(:spreadsheet) { SpreadsheetBuilder.new(resource.uri, [ao.uri], min_subrecords, extra_subrecords, min_notes, selected_columns) }

  let(:file_name) { spreadsheet.build_filename }

  let(:job) do
    build(:json_job,
          :job_type => 'bulk_update_job')
  end

  let(:bulk_updater) { BulkUpdater.new(test_file, job) }

  it "initializes bulk update spreadsheet" do
    expect(bulk_updater.filename).to eq(test_file)
    expect(bulk_updater.job['job_type']).to eq('bulk_update_job')
  end

  it "determines resource ids" do
    allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
    expect(bulk_updater.resource_ids_in_play(file_name)).to eq([resource.id])
  end

  it "determines archival object ids" do
    expect(bulk_updater.extract_ao_ids(test_file)).to eq([1, 2, 5, 6])
  end

  describe "checks the spreadsheet" do
    context "spreadsheet has errors" do
      it "returns error" do
        allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
        allow(bulk_updater).to receive(:resource_ids_in_play).with(file_name).and_return([resource.id,'asdrf'])
        expect {bulk_updater.check_sheet(file_name)}.to raise_error(BulkUpdater::BulkUpdateFailed)
      end
    end

    context "spreadsheet has no errors" do
      it "returns nil" do
        allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
        allow(bulk_updater).to receive(:resource_ids_in_play).with(file_name).and_return([resource.id])
        expect(bulk_updater.check_sheet(file_name)).to be_nil
      end
    end
  end

  describe "extracts the columns" do
    context "spreadsheet has errors" do
      it "returns error" do
        expect {bulk_updater.extract_columns(test_file_with_errors)}.to raise_error(RuntimeError, /Column definition not found for 1/)
      end
    end
    context "spreadsheet has no errors" do
      it "extracts columns" do
        expect(bulk_updater.extract_columns(test_file).count).to eq(186)
      end
    end
  end

  describe "apply deletes" do
    context "bulk_updater_apply_deletes is false" do
      it "returns false" do
        AppConfig[:bulk_updater_apply_deletes] = false
        expect(BulkUpdater.apply_deletes?).to be false
      end
    end

    context "bulk_updater_apply_deletes is true" do
      it "returns true" do
        AppConfig[:bulk_updater_apply_deletes] = true
        expect(BulkUpdater.apply_deletes?).to be true
      end
    end
  end

  it "finds subrecord columns" do
    cols = bulk_updater.extract_columns(test_file)
    expect(bulk_updater.find_subrecord_columns(cols).count).to eq(23)
  end

  describe "creates missing top containers check" do
    context "job has key create_missing_top_containers" do
      it "returns value from job" do
        allow(bulk_updater.job.job).to receive(:has_key?).with('create_missing_top_containers').and_return(true)
        bulk_updater.job.job['create_missing_top_containers'] = true
        expect(bulk_updater.create_missing_top_containers?).to be true
        bulk_updater.job.job['create_missing_top_containers'] = false
        expect(bulk_updater.create_missing_top_containers?).to be false
      end
    end

    context "AppConfig.has_key?(:bulk_updater_create_missing_top_containers)" do
      it "returns value from AppConfig" do
        allow(bulk_updater.job.job).to receive(:has_key?).with('create_missing_top_containers').and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:bulk_updater_create_missing_top_containers).and_return(true)
        AppConfig[:bulk_updater_create_missing_top_containers] = true
        expect(bulk_updater.create_missing_top_containers?).to be true
        AppConfig[:bulk_updater_create_missing_top_containers] = false
        expect(bulk_updater.create_missing_top_containers?).to be false
      end
    end

    context "neither job nor AppConfig have keys for creating missing top containers" do
      it "returns false" do
        allow(AppConfig).to receive(:has_key?).with(:bulk_updater_create_missing_top_containers).and_return(false)
        allow(bulk_updater.job.job).to receive(:has_key?).with('create_missing_top_containers').and_return(false)
        expect(bulk_updater.create_missing_top_containers?).to be false
      end
    end
  end

  describe "#create_missing_top_containers" do
    let(:job) { build(:json_job, job_type: 'bulk_update_job') }
    let(:bulk_updater) { BulkUpdater.new(test_file_with_new_top_containers, job) }
    let(:in_sheet) { { BulkUpdater::TopContainerCandidate.new("box", "1", "123") => nil } }

    context "when create_missing_top_containers? is true" do
      before do
        allow(bulk_updater).to receive(:create_missing_top_containers?).and_return(true)
        allow(job).to receive(:write_output).and_return("")
      end

      it "creates missing top containers" do
        bulk_updater.instance_variable_set(:@top_containers_in_resource, { BulkUpdater::TopContainerCandidate.new("box", "3", "345") => "/repositories/2/top_containers/2" })

        bulk_updater.create_missing_top_containers(in_sheet, job)

        expect(bulk_updater.instance_variable_get(:@top_containers_in_resource)).to eq({ BulkUpdater::TopContainerCandidate.new("box", "3", "345") => "/repositories/2/top_containers/2", BulkUpdater::TopContainerCandidate.new("box", "1", "123") => "/repositories/2/top_containers/3"})
      end
    end

    context "when create_missing_top_containers? is false" do
      before do
        allow(bulk_updater).to receive(:create_missing_top_containers?).and_return(false)
      end

      it "does not create missing top containers" do
        expect(bulk_updater).not_to receive(:extract_top_containers_from_sheet)
        expect(TopContainer).not_to receive(:create_from_json)

        expect(bulk_updater).not_to receive(:create_missing_top_containers)

        expect(bulk_updater.instance_variable_get(:@top_containers_in_resource)).to be_nil
      end
    end
  end

  it "determines default record values" do
    expect(bulk_updater.default_record_values('note_jsonmodel')).to eq({})
    expect(bulk_updater.default_record_values('dates')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['dates'])
    expect(bulk_updater.default_record_values('instance')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['instance'])
    expect(bulk_updater.default_record_values('note_multipart')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['note_multipart'])
    expect(bulk_updater.default_record_values('note_singlepart')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['note_singlepart'])
  end
end
