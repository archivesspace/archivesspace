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

  describe "#initialize" do
    it "sets the filename" do
      expect(bulk_updater.filename).to eq(test_file)
    end

    it "sets the job" do
      expect(bulk_updater.job).to eq(job)
    end

    it "initializes errors as an empty array" do
      expect(bulk_updater.errors).to eq([])
    end

    it "initializes updated_uris as an empty array" do
      expect(bulk_updater.updated_uris).to eq([])
    end
  end

  describe "#extract_ao_ids" do
    it "determines resource ids" do
      allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
      expect(bulk_updater.resource_ids_in_play(file_name)).to eq([resource.id])
    end

    it "determines archival object ids" do
      expect(bulk_updater.extract_ao_ids(test_file)).to eq([1, 2, 5, 6])
    end
  end

  describe "#check_sheet" do
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

  describe "#extract_columns" do
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

  describe "#apply_deletes?" do
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

  describe "#find_subrecord_columns" do
    it "finds subrecord columns" do
      cols = bulk_updater.extract_columns(test_file)
      expect(bulk_updater.find_subrecord_columns(cols).count).to eq(23)
    end

    it "finds no subrecord columns" do
      cols = {}
      expect(bulk_updater.find_subrecord_columns(cols).count).to eq(0)
    end
  end

  describe "#create_missing_top_containers?" do
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

        expect(bulk_updater.instance_variable_get(:@top_containers_in_resource).keys).to include(in_sheet.keys.first)
        expect(bulk_updater.instance_variable_get(:@top_containers_in_resource).count).to eq(2)
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

  describe "#default_record_values" do
    it "determines default record values" do
      expect(bulk_updater.default_record_values('note_jsonmodel')).to eq({})
      expect(bulk_updater.default_record_values('dates')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['dates'])
      expect(bulk_updater.default_record_values('instance')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['instance'])
      expect(bulk_updater.default_record_values('note_multipart')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['note_multipart'])
      expect(bulk_updater.default_record_values('note_singlepart')).to eq(BulkUpdater::SUBRECORD_DEFAULTS['note_singlepart'])
    end
  end

  describe "#apply_sub_record_updates" do
    let(:row) { double("Row") }
    let(:ao_json) { ao }
    let(:subrecord_updates_by_index) { { 'dates' => { 0 => { 'label' => 'updated' } } } }

    it "determines that there are subrecord updates" do
      expect(bulk_updater.apply_sub_record_updates(row, ao_json, subrecord_updates_by_index)).to be true
    end

    it "determines that there are no subrecord updates" do
      subrecord_updates_by_index = {}
      expect(bulk_updater.apply_sub_record_updates(row, ao_json, subrecord_updates_by_index)).to be false
    end
  end

  describe "#extract_accessions_from_sheet" do
    let(:db) { double("db") }
    let(:related_accession_columns) { {"related_accessions/0/id_0"=>SpreadsheetBuilder::StringColumn.new(:related_accession, :id_0, :property_name => :related_accessions, :i18n => 'ID Part 1'),
                                        "related_accessions/0/id_1"=>SpreadsheetBuilder::StringColumn.new(:related_accession, :id_1, :property_name => :related_accessions, :i18n => 'ID Part 2'),
                                        "related_accessions/0/id_2"=>SpreadsheetBuilder::StringColumn.new(:related_accession, :id_2, :property_name => :related_accessions, :i18n => 'ID Part 3'),
                                        "related_accessions/0/id_3"=>SpreadsheetBuilder::StringColumn.new(:related_accession, :id_3, :property_name => :related_accessions, :i18n => 'ID Part 4')} }
    it "extracts accessions from the sheet" do
      allow(db).to receive(:[]).with(:accession).and_return(db)
      allow(db).to receive(:filter).and_return(db)
      allow(db).to receive(:select).with(:id, :repo_id, :identifier).and_return(
        [
          { id: 1, repo_id: 2, identifier: "[\"1\", \"2\", \"3\", \"4\"]" },
          { id: 2, repo_id: 2, identifier: "[\"5\", \"6\", \"7\", \"8\"]" }
        ]
      )

      accessions = bulk_updater.extract_accessions_from_sheet(db, test_file, related_accession_columns)

      expect(accessions).to eq({ BulkUpdater::AccessionCandidate.new("1", "2", "3", "4") => "/repositories/2/accessions/1",
                                  BulkUpdater::AccessionCandidate.new("5", "6", "7", "8") => "/repositories/2/accessions/2"})
    end
  end

  describe "#apply_date_defaults" do
    let(:subrecord) { { 'end' => nil } }

    it "sets date_type to 'single' when 'end' is nil" do
      expect(bulk_updater.apply_date_defaults(subrecord)['date_type']).to eq('single')
    end

    it "sets date_type to 'inclusive' when 'end' is not nil" do
      subrecord['end'] = '2022-01-01'
      expect(bulk_updater.apply_date_defaults(subrecord)['date_type']).to eq('inclusive')
    end
  end

  describe "#apply_instance_updates" do
    let(:row) { double("Row") }
    let(:ao_json) { ao }
    let(:instance_updates_by_index) { { 0 => { 'instance_type' => 'text' } } }
    let(:digital_object_updates_by_index) { {} }

    it "determines there are instance updates" do
      expect(bulk_updater.apply_instance_updates(row, ao_json, instance_updates_by_index, digital_object_updates_by_index)).to be true
    end

    it "determines there are no instance updates" do
      instance_updates_by_index = {}
      expect(bulk_updater.apply_instance_updates(row, ao_json, instance_updates_by_index, digital_object_updates_by_index)).to be false
    end
  end

  describe "#apply_lang_material_updates" do
    let(:row) { double('Row') }
    let(:ao_json) { ao }
    let(:lang_material_updates_by_index) { { language_and_script: { 0 => { 'language' => 'English', 'script' => 'Latin' } }, note_langmaterial: {} } }

    context 'when existing language_and_script is empty' do
      before do
        allow(ao_json).to receive(:lang_materials).and_return([])
      end

      it 'determines there are lang_material updates' do
        expect(bulk_updater.apply_lang_material_updates(row, ao_json, lang_material_updates_by_index)).to be true
      end

      it 'determines there are no lang_material updates' do
        lang_material_updates_by_index = { language_and_script: {}, note_langmaterial: {} }
        expect(bulk_updater.apply_lang_material_updates(row, ao_json, lang_material_updates_by_index)).to be false
      end
    end

    context 'when existing language_and_script is not empty' do
      let(:existing_language_and_script) { { 'language' => 'Spanish', 'script' => 'Latin' } }

      before do
        allow(ao_json).to receive(:lang_materials).and_return([
          {
            'jsonmodel' => 'lang_material',
            'language_and_script' => existing_language_and_script
          }
        ])
      end

      it 'determines there are lang_material updates' do
        expect(bulk_updater.apply_lang_material_updates(row, ao_json, lang_material_updates_by_index)).to be true
      end

      it 'determines there are no lang_material updates' do
        lang_material_updates_by_index = { language_and_script: {}, note_langmaterial: {} }
        expect(bulk_updater.apply_lang_material_updates(row, ao_json, lang_material_updates_by_index)).to be false
      end
    end
  end

  describe "#delete_empty_notes" do
    it 'determines there are empty notes to delete' do
      ao_json = ao
      ao_json["notes"][1]["subnotes"][0]["content"] = ''

      expect(bulk_updater.delete_empty_notes(ao_json)).to be true
    end

    it 'determines there are no empty notes to delete' do
      ao_json = ao

      expect(bulk_updater.delete_empty_notes(ao_json)).to be false
    end
  end

  describe "#apply_notes_column" do
    let(:row) { double("row") }
    let(:column) { double("column") }
    let(:value) { "New note content" }
    let(:ao_json) { ao }
    let(:notes_by_type) { {} }
    let(:note_jsonmodel) { "note_singlepart" }
    let(:note_type) { "note" }

    it "will create a new note if it doesn't exist" do
      allow(column).to receive(:sanitise_incoming_value).with(value).and_return(value)
      allow(column).to receive(:index).at_least(:once).and_return(0)
      allow(column).to receive(:property_name).and_return("note")
      allow(column).to receive(:name).at_least(:once).and_return("content")

      expect(bulk_updater.apply_notes_column(row, column, value, ao_json, notes_by_type, note_jsonmodel, note_type)).to be true
    end

    it "will update an existing note" do
      existing_note = { "jsonmodel_type" => "note_singlepart", "type" => "note", "content" => ["Old note content"] }
      notes_by_type[note_type] = { 0 => existing_note }

      allow(column).to receive(:sanitise_incoming_value).with(value).and_return(value)
      allow(column).to receive(:index).at_least(:once).and_return(0)
      allow(column).to receive(:property_name).and_return("note")
      allow(column).to receive(:name).at_least(:once).and_return("content")

      expect(bulk_updater.apply_notes_column(row, column, value, ao_json, notes_by_type, note_jsonmodel, note_type)).to be true
    end

    it "will delete a note if the value is empty" do
      existing_note = { "jsonmodel_type" => "note_singlepart", "type" => "note", "content" => ["Old note content"] }
      notes_by_type[note_type] = { 0 => existing_note }

      allow(column).to receive(:sanitise_incoming_value).with(value).and_return("")
      allow(column).to receive(:index).at_least(:once).and_return(0)
      allow(column).to receive(:property_name).and_return("note")
      allow(column).to receive(:name).at_least(:once).and_return("content")

      expect(bulk_updater.apply_notes_column(row, column, value, ao_json, notes_by_type, note_jsonmodel, note_type)).to be true
    end
  end

  describe "#apply_archival_object_column" do
    let(:row) { double("row") }
    let(:column) { double("column") }
    let(:path) { "path" }
    let(:clean_value) { 100 }
    let(:value) { 1 }
    let(:ao_json) { { "uri" => "ao_uri", "lock_version" => 1 } }

    context "when the column name is :uri" do
      before(:each) do
        allow(column).to receive(:name).and_return(:uri)
        allow(Integer).to receive(:call).with(value).and_return(1)
      end

      it "returns true" do
        allow(column).to receive(:sanitise_incoming_value).with(value).and_return(clean_value)
        expect(bulk_updater.apply_archival_object_column(row, column, path, value, ao_json)).to be true
      end

      it "returns false if the value is the same as ao_json[path]" do
        allow(column).to receive(:sanitise_incoming_value).with(value).and_return(value)
        ao_json[path] = value
        expect(bulk_updater.apply_archival_object_column(row, column, path, value, ao_json)).to be false
      end
    end

    context "when the column name is :id" do
      before do
        allow(column).to receive(:name).and_return(:id)
      end

      it "returns false" do
        expect(bulk_updater.apply_archival_object_column(row, column, path, value, ao_json)).to be false
      end
    end

    context "when the column name is :lock_version" do
      before do
        allow(column).to receive(:name).and_return(:lock_version)
      end

      it "returns false" do
        expect(bulk_updater.apply_archival_object_column(row, column, path, value, ao_json)).to be false
      end
    end
  end

  describe '#apply_related_accession_updates' do
    let(:row) { double('row') }
    let(:ao_json) { ao }
    let(:existing_subrecord) { double('existing_subrecord') }
    let(:related_accession_updates_by_index) { { 0 => { 'id_0' => 'ACCESSION_ID0', 'id_1' => 'ACCESSION_ID1', 'id_2' => 'ACCESSION_ID2', 'id_3' => 'ACCESSION_ID3' } } }

    it 'determines the record has changed and returns true' do
      allow(ao_json).to receive(:accession_links).and_return({ 0 => { 'id_0' => 'ACCESSION_ID', 'id_1' => 'ACCESSION_ID', 'id_2' => 'ACCESSION_ID', 'id_3' => 'ACCESSION_ID', 'ref' => "/repositories/2/accessions/2" } })
      bulk_updater.instance_variable_set(:@accessions_in_sheet, { BulkUpdater::AccessionCandidate.new("ACCESSION_ID0", "ACCESSION_ID1", "ACCESSION_ID2", "ACCESSION_ID3") => "/repositories/2/accessions/1" })

      expect(bulk_updater.apply_related_accession_updates(row, ao_json, related_accession_updates_by_index)).to be true
    end

    it 'determines the record has not changed and returns false' do
      allow(ao_json).to receive(:accession_links).and_return({ 0 => { 'id_0' => 'ACCESSION_ID', 'id_1' => 'ACCESSION_ID', 'id_2' => 'ACCESSION_ID', 'id_3' => 'ACCESSION_ID', 'ref' => "/repositories/2/accessions/1" } })
      bulk_updater.instance_variable_set(:@accessions_in_sheet, { BulkUpdater::AccessionCandidate.new("ACCESSION_ID0", "ACCESSION_ID1", "ACCESSION_ID2", "ACCESSION_ID3") => "/repositories/2/accessions/1" })

      expect(bulk_updater.apply_related_accession_updates(row, ao_json, related_accession_updates_by_index)).to be false
    end
  end

  describe '#extract_top_containers_for_resource' do
    let(:db) { double('db') }
    let(:resource_id) { 1 }
    let(:top_container_id) { 1 }
    let(:repo_id) { 1 }
    let(:top_container_type_id) { 1 }
    let(:top_container_indicator) { 'Box 1' }
    let(:top_container_barcode) { '1234567890' }
    let(:row) do
      {
        top_container_id: top_container_id,
        repo_id: repo_id,
        top_container_type_id: top_container_type_id,
        top_container_indicator: top_container_indicator,
        top_container_barcode: top_container_barcode
      }
    end

    before do
      allow(db).to receive(:[]).with(:instance).and_return(db)
      allow(db).to receive(:join).and_return(db)
      allow(db).to receive(:filter).and_return(db)
      allow(db).to receive(:select).and_return([row])
      allow(BackendEnumSource).to receive(:value_for_id).with('container_type', top_container_type_id).and_return('Box')
      allow(JSONModel::JSONModel(:top_container)).to receive(:uri_for).with(top_container_id, repo_id: repo_id).and_return('/top_containers/1')
    end

    it 'returns a hash of top containers for the given resource' do
      expected_result = {
        BulkUpdater::TopContainerCandidate.new('Box', 'Box 1', '1234567890') => '/top_containers/1'
      }
      result = bulk_updater.extract_top_containers_for_resource(db, resource_id)
      expect(result).to eq(expected_result)
    end
  end

  describe '#resource_ids_in_play' do
    it 'returns an array of resource IDs' do
      allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
      expect(bulk_updater.resource_ids_in_play(file_name)).to eq([resource.id])
    end
  end

  describe '#apply_digital_objects_changes' do
    let(:in_sheet) do
      {
        BulkUpdater::DigitalObjectCandidate.new('123', 'Digital Object 1', true, 'file_uri_1', 'Caption 1', true) => true
      }
    end

    let(:db) { double('db') }

    context 'when digital object already exists' do
      let(:identifiers_by_digital_object_id) { [ 123 ] }
      let(:dig_obj) do
        build(:json_digital_object, :digital_object_id => '123', :lock_version => 1)
      end

      before do
        allow(job).to receive(:write_output)
        allow(db).to receive(:[]).with(:digital_object).and_return(db)
        allow(db).to receive(:filter).and_return(db)
        allow(db).to receive(:select).with(:id, :repo_id, :digital_object_id).and_return(
          [
            { id: 1, repo_id: 2, digital_object_id: "123" }
          ]
        )

        allow(DigitalObject).to receive(:filter).with(id: [1]).and_return(double('DigitalObjectFilter', all: [DigitalObject.create_from_json(dig_obj)]))
        allow(DigitalObject).to receive(:sequel_to_jsonmodel).and_return([dig_obj])
      end

      it 'updates the existing digital object' do
        expect(DigitalObject).not_to receive(:create_from_json)
        expect_any_instance_of(DigitalObject).to receive(:update_from_json)
        bulk_updater.apply_digital_objects_changes(in_sheet, job, db)
        expect(bulk_updater.updated_uris).to eq(['/repositories/2/digital_objects/1'])
      end
    end

    context 'when digital object does not exist' do
      let(:identifiers_by_digital_object_id) { {} }
      let(:dig_obj) do
        build(:json_digital_object, :digital_object_id => '123', :lock_version => 1)
      end

      before do
        allow(job).to receive(:write_output)
        allow(db).to receive(:[]).with(:digital_object).and_return(db)
        allow(db).to receive(:filter).and_return(db)
        allow(db).to receive(:select).with(:id, :repo_id, :digital_object_id).and_return(
          [
            { id: 1, repo_id: 2, digital_object_id: "DOI1" }
          ]
        )
        allow(DigitalObject).to receive(:create_from_json).and_return(double('DigitalObject', uri: '/digital_objects/2', id: 2))
      end

      it 'creates a new digital object' do
        bulk_updater.apply_digital_objects_changes(in_sheet, job, db)
        expect(bulk_updater.updated_uris).to eq(['/digital_objects/2'])
      end
    end
  end

  describe "#extract_digital_objects_from_sheet" do
    let(:digital_object_columns) { { "digital_object/0/digital_object_id" => SpreadsheetBuilder::StringColumn.new(:digital_object, :digital_object_id, :property_name => :digital_object, :i18n => 'ID'),
                                     "digital_object/0/digital_object_title" => SpreadsheetBuilder::StringColumn.new(:digital_object, :digital_object_title, :property_name => :digital_object, :i18n => 'Title'),
                                     "digital_object/0/digital_object_publish" => SpreadsheetBuilder::BooleanColumn.new(:digital_object, :digital_object_publish, :property_name => :digital_object, :i18n => 'Publish'),
                                     "digital_object/0/file_version_file_uri" => SpreadsheetBuilder::StringColumn.new(:file_version, :file_version_file_uri, :property_name => :file_version, :i18n => 'File URI'),
                                     "digital_object/0/file_version_caption" => SpreadsheetBuilder::StringColumn.new(:file_version, :file_version_caption, :property_name => :file_version, :i18n => 'Caption'),
                                     "digital_object/0/file_version_publish" => SpreadsheetBuilder::BooleanColumn.new(:file_version, :file_version_publish, :property_name => :file_version, :i18n => 'Publish') } }

    it "extracts digital objects from the sheet" do
      digital_objects = bulk_updater.extract_digital_objects_from_sheet(test_file, digital_object_columns)

      expect(digital_objects).to eq({ BulkUpdater::DigitalObjectCandidate.new("DOI1", "DO Title", false, "/dig_obj/file.jpg", "File Caption", false) => nil })
    end
  end

  describe "#extract_top_containers_from_sheet" do
    let(:top_container_columns) { { "instances/0/top_container_type" => SpreadsheetBuilder::StringColumn.new(:instance, :top_container_type, :property_name => :instances, :i18n => 'Top Container Type'),
                                    "instances/0/top_container_indicator" => SpreadsheetBuilder::StringColumn.new(:instance, :top_container_indicator, :property_name => :instances, :i18n => 'Top Container Indicator'),
                                    "instances/0/top_container_barcode" => SpreadsheetBuilder::BooleanColumn.new(:instance, :top_container_barcode, :property_name => :instances, :i18n => 'Top Container Barcode') } }

    it "extracts top containers from the sheet" do
      top_containers = bulk_updater.extract_top_containers_from_sheet(test_file_with_top_containers, top_container_columns)

      expect(top_containers).to eq({ BulkUpdater::TopContainerCandidate.new("Box [box]", "1", nil) => nil,
                                     BulkUpdater::TopContainerCandidate.new("Box [box]", "2", nil) => nil,
                                     BulkUpdater::TopContainerCandidate.new("Reel [reel]", "1", nil) => nil,
                                     BulkUpdater::TopContainerCandidate.new("oversize [oversize]", "1-12", nil) => nil })
    end
  end
end
