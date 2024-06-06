require_relative 'spec_helper'

describe 'Bulk Updater model' do
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
  let(:ao) { create(:json_archival_object, :resource => {:ref => resource.uri}, :dates => dates) }
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

  let(:bulk_updater) { BulkUpdater.new(file_name, job) }

  it "initializes bulk update spreadsheet" do
    expect(bulk_updater.filename).to eq(file_name)
    expect(bulk_updater.job['job_type']).to eq('bulk_update_job')
  end

  describe "#check_sheet" do
    context "has errors" do
      it "return errors" do
        allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
        allow(bulk_updater).to receive(:resource_ids_in_play).with(file_name).and_return(['12345','asdrf'])
        expect {bulk_updater.check_sheet(file_name)}.to raise_error(BulkUpdater::BulkUpdateFailed)
      end
    end

    context "no errors" do
      it "returns nil" do
        allow(bulk_updater).to receive(:extract_ao_ids).with(file_name).and_return([ao.id])
        allow(bulk_updater).to receive(:resource_ids_in_play).with(file_name).and_return([resource.id])
        expect(bulk_updater.check_sheet(file_name)).to be_nil
      end
    end
  end
end
