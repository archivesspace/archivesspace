require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/accession_converter'

describe 'Accession import batch' do
  context 'when the provided CSV has accessions with valid date types' do
    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/accession_import_with_valid_date_types.csv", File.dirname(__FILE__))
    end

    it 'successfully imports the accessions' do
      accessions_count_before = ::Accession.count

      converter = Converter.for('accession_csv', csv_file, {:import_events => false, :import_subjects => true})
      expect(converter).to be_a AccessionConverter

      converter.run

      job = Job.new
      ticker = Ticker.new(job)

      File.open(converter.get_output_path, "r") do |fh|
        batch = StreamingImport.new(fh, ticker)
        batch.process
      end

      accessions_count_after = ::Accession.count
      expect(accessions_count_after).to eq accessions_count_before + 5
    end
  end

  context 'when the provided CSV has accessions with invalid date types' do
    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/accession_import_with_invalid_date_types.csv", File.dirname(__FILE__))
    end

    it 'fails to import the accession' do
      accessions_count_before = ::Accession.count

      converter = Converter.for('accession_csv', csv_file, {:import_events => false, :import_subjects => true})
      expect(converter).to be_a AccessionConverter

      expect do
        converter.run
      end.to raise_error do |error|
        expect(error).to be_a AccessionConverterInvalidDateTypeError
        expect(error.message).to eq 'Invalid date type provided: inclusive dates; must be one of: ["bulk", "inclusive", "single"]; Date provided: #<JSONModel(:date) {"jsonmodel_type"=>"date", "uri"=>nil, "label"=>"Creation", "expression"=>"ca. 2006-2008", "begin"=>"2006", "end"=>"2008", "date_type"=>"inclusive dates"}>;'

        accessions_count_after = ::Accession.count
        expect(accessions_count_before).to eq accessions_count_after
      end
    end
  end
end
