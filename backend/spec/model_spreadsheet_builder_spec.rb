require_relative 'spec_helper'

describe 'Spreadsheet Builder model' do
  let(:dates) { [build(:json_date)] }
  let(:notes) { [build(:json_note_singlepart), build(:json_note_multipart)] }
  let(:extents) { [build(:json_extent, {:portion => generate(:portion)})] }
  let(:accession) { create(:json_accession) }
  let(:resource) { create(:json_resource,
                          :extents => extents,
                          :dates => dates,
                          :notes => notes,
                          :related_accessions => [{'ref' => accession.uri}]) }
  let(:ao) { create(:json_archival_object, :resource => {:ref => resource.uri}, :dates => dates) }
  let(:min_subrecords) { 0 }
  let(:extra_subrecords) { 0 }
  let(:min_notes) { 0 }
  let(:selected_columns) { ['level', 'component_id', 'related_accession'] }

  let(:spreadsheet) { SpreadsheetBuilder.new(resource.uri, [ao.uri], min_subrecords, extra_subrecords, min_notes, selected_columns) }

  def archival_object_cols
    result = []
    SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:archival_object).each do |column|
      result << column if spreadsheet.selected?(column.name.to_s)
    end
    result
  end

  def related_accessions_cols
    result = []
    spreadsheet.related_accessions_iterator do |_, index|
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:related_accession).each do |column|
        column = column.clone
        column.index = index
        result << column
      end
    end
    result
  end

  it "creates file name" do
    expect(spreadsheet.build_filename).to eq("bulk_update.resource_#{resource.id}.#{Date.today.iso8601}.xlsx")
  end

  it "calculates subrecord counts" do
    expect(spreadsheet.instance_variable_get(:@subrecord_counts)).to eq(spreadsheet.calculate_subrecord_counts(min_subrecords, extra_subrecords, min_notes))
  end

  it "determines human_readable_headers correctly" do
    header_labels = []
    SpreadsheetBuilder::FIELDS_OF_INTEREST.keys.each do |k|
      header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST[k.to_sym].map {|e| e.header_label}
    end
    expect(spreadsheet.human_readable_headers - header_labels.flatten!).to eq([])
  end

  it "determines machine_readable_headers correctly" do
    expect(spreadsheet.machine_readable_headers.sort).to eq(archival_object_cols.append(related_accessions_cols).flatten.map {|col| col.path}.sort)
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
end
