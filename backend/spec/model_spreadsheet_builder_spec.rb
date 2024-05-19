require_relative 'spec_helper'

describe 'Spreadsheet Builder model' do
  let(:dates) { [build(:json_date)] }
  let(:notes) { [build(:json_note_singlepart), build(:json_note_multipart)] }
  let(:extents) { [build(:json_extent, {:portion => generate(:portion)})] }
  let(:resource) { create(:json_resource, 
                          :extents => extents, 
                          :dates => dates,
                          :notes => notes) }
  let(:ao) { create(:json_archival_object,
                    :dates => [],
                    :resource => {:ref => resource.uri})
  }

  let(:min_subrecords) { 0 }
  let(:extra_subrecords) { 0 }
  let(:min_notes) { 0 }
  let(:selected_columns) { ['level', 'component_id'] }
  let(:spreadsheet) { SpreadsheetBuilder.new(resource.uri,[ao.uri],min_subrecords,extra_subrecords,min_notes,selected_columns) }
  let(:subrecord_counts) { spreadsheet.calculate_subrecord_counts(min_subrecords, extra_subrecords, min_notes) }

  it "creates file name" do
    expect(spreadsheet.build_filename).to eq("bulk_update.resource_#{resource.id}.#{Date.today.iso8601}.xlsx")
  end

  describe '#selected?' do
    context 'unselected column' do
      it "returns false" do
        expect(spreadsheet.selected?('unselected_column')).to be false
      end
    end

    context 'selected column' do
      it "returns true" do
        expect(spreadsheet.selected?(selected_columns[0])).to be true
      end
    end
  end

  it "computes the correct column reference" do
    expect(spreadsheet.index_to_col_reference(4)).to eq('E')
    expect(spreadsheet.index_to_col_reference(40)).to eq('AO')
  end

  context "archival objects only" do
    it "calculates subrecord counts" do
      expect(spreadsheet.instance_variable_get(:@subrecord_counts)).to eq(subrecord_counts)
    end

    it "determines human_readable_headers correctly" do
      header_labels = []
      SpreadsheetBuilder::FIELDS_OF_INTEREST.keys.each do |k|
        header_labels << SpreadsheetBuilder::FIELDS_OF_INTEREST[k.to_sym].map{|e| e.header_label}
      end
      expect(spreadsheet.human_readable_headers - header_labels.flatten!).to eq([])
    end

    it "determines machine_readable_headers correctly" do
      expect(spreadsheet.machine_readable_headers.sort).to eq((selected_columns + SpreadsheetBuilder::ALWAYS_FIELDS).sort)
    end

    it "determines selected columns" do
      expect(spreadsheet.instance_variable_get(:@selected_columns).sort).to eq((selected_columns + SpreadsheetBuilder::ALWAYS_FIELDS).sort)
    end

    it "computes all_columns correctly" do
      result = []
      SpreadsheetBuilder::FIELDS_OF_INTEREST.fetch(:archival_object).each do |column|
        result << column if spreadsheet.selected?(column.name.to_s)
      end
      expect(spreadsheet.all_columns.count).to eq(result.count)
      expect(spreadsheet.all_columns).to eq(result)
    end
  end
end
