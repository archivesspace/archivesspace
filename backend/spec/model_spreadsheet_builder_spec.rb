require_relative 'spec_helper'

describe 'Spreadsheet Builder model' do
  let(:dates) { [build(:json_date)] }
  let(:notes) { [build(:json_note_singlepart), build(:json_note_multipart)] }
  let(:extents) { [build(:json_extent, {:portion => generate(:portion)})] }
  let(:accession) { create(:json_accession) }
  let(:lang_materials) { [build(:json_lang_material)] }
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


  let(:all_cols) { spreadsheet.all_columns }

  it "creates file name" do
    expect(spreadsheet.build_filename).to eq("bulk_update.resource_#{resource.id}.#{Date.today.iso8601}.xlsx")
  end

  it "calculates subrecord counts" do
    expect(spreadsheet.instance_variable_get(:@subrecord_counts)).to eq(spreadsheet.calculate_subrecord_counts(min_subrecords, extra_subrecords, min_notes))
  end

  it "determines human_readable_headers correctly" do
    header_labels = []
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:archival_object).map {|e| e.header_label}
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:language_and_script).map {|e| e.header_label}
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:related_accession).map {|e| e.header_label}
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:note_langmaterial).map {|e| e.header_label}
    (0..min_notes).each do |i|
      [SpreadsheetBuilder::MULTIPART_NOTES_OF_INTEREST, SpreadsheetBuilder::SINGLEPART_NOTES_OF_INTEREST].flatten.each do |n|
        start = "Note #{I18n.t("enumerations._note_types.#{n.to_s}", :default => "#{n.to_s}")} - #{i} "
        header_labels << [start + "- Content", start + "- Label"]
      end
      start = "Note #{I18n.t("enumerations._note_types.accessrestrict", :default => "accessrestrict")} - #{i+1} "
      header_labels << [start + "- Begin", start + "- End", start + "- Type"]
    end
    (1..min_subrecords).each do |i|
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:date).each do |d|
        header_labels << ["Date #{i} - #{d.column.to_s.split('_')[0].capitalize()}"]
      end
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:digital_object).each do |d|
        header_labels << ["Digital Object #{i} - #{d.instance_variable_get(:@i18n)}"]
      end
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:instance).each do |d|
        header_labels << ["Instance #{i} - #{d.instance_variable_get(:@i18n)}"]
      end
    end
    SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:extent).each do |e|
      (0..min_subrecords+extra_subrecords-2).each do |i|
        header_labels << ["Extent #{i} - #{e.instance_variable_get(:@i18n)}"]
      end
    end
    expect(spreadsheet.human_readable_headers.sort - header_labels.flatten!.sort).to eq([])
  end

  it "determines machine_readable_headers correctly" do
    header_labels = []
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:archival_object).map {|e| e.path}
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:language_and_script).map {|e| "language_and_script/0/" + e.column.to_s.sub('_id', '')}
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:related_accession).map {|e| "related_accessions/0/" + e.column.to_s}
    header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:note_langmaterial).map {|e| "note_langmaterial/0/" + e.column.to_s}
    (0..min_notes-1).each do |i|
      [SpreadsheetBuilder::MULTIPART_NOTES_OF_INTEREST, SpreadsheetBuilder::SINGLEPART_NOTES_OF_INTEREST].flatten.each do |n|
        header_labels << ["note/#{n}/#{i}/content", "note/#{n}/#{i}/label"]
      end
      SpreadsheetBuilder::EXTRA_NOTE_FIELDS.fetch(:accessrestrict).each do |n|
        header_labels << ["note/accessrestrict/#{i}/#{n.column.to_s.gsub('_id', '')}"]
      end
    end
    (0..min_subrecords-1).each do |i|
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:date).each do |d|
        header_labels << ["dates/#{i}/#{d.column.to_s.split('_')[0]}"]
      end
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:digital_object).each do |d|
        header_labels << ["digital_object/#{i}/#{d.column.to_s}"]
      end
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:instance).each do |d|
        header_labels << ["instances/#{i}/#{d.column.to_s.sub('_id', '')}"]
      end
    end
    SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:extent).each do |d|
      (0..min_subrecords+extra_subrecords-2).each do |i|
        header_labels << ["extents/#{i}/#{d.column.to_s.sub('_id', '')}"]
      end
    end
    expect(spreadsheet.machine_readable_headers.sort - header_labels.flatten!.sort).to eq([])
  end

  it "determines selected columns" do
    expect(spreadsheet.instance_variable_get(:@selected_columns)).to eq(selected_columns + SpreadsheetBuilder::ALWAYS_FIELDS)
  end

  describe "#selected?" do
    context "Unselected Column" do
      it "returns false" do
        expect(spreadsheet.selected?('unselected_column')).to be false
      end
    end

    context "Selected Column" do
      it "returns true" do
        expect(spreadsheet.selected?(selected_columns[0])).to be true
      end
    end
  end

  it "computes the column reference correctly" do
    expect(spreadsheet.index_to_col_reference(13)).to eq('N')
    expect(spreadsheet.index_to_col_reference(43)).to eq('AR')
  end
end
