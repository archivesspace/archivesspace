require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/accession_converter'

describe 'Accession converter' do
  def my_converter
    AccessionConverter
  end

  context 'when all accessions provided in the CSV are valid' do
    let(:converted_entries) do
      convert(csv_file)
    end

    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/aspace_accession_import_template.csv", File.dirname(__FILE__))
    end

    let(:converted_accessions) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'] == 'accession'
      end
    end

    let(:converted_agents) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'].include?('agent_')
      end
    end

    let(:converted_subjects) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'] == 'subject'
      end
    end

    let(:converted_events) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'] == 'event'
      end
    end

    let(:converted_dates) do
      converted_dates = []

      converted_accessions.each do |accession|
        converted_dates = converted_dates + accession['dates']
      end

      converted_dates
    end

    it "successfully parses and converts records from the CSV" do
      expect(converted_accessions.count).to eq(10)
      expect(converted_agents.count).to eq(5)

      telephones = converted_agents.first['agent_contacts'].map { |c| c['telephones'] }.flatten
      expect(telephones.count).to eq(2)
      expect(telephones[0]['number_type']).to eq('fax')
      expect(telephones[0]['number']).to eq('999-444-4444')
      expect(telephones[1]['number_type']).to eq('home')
      expect(telephones[1]['ext']).to eq('247')

      expect(converted_subjects.count).to eq(8)

      expect(converted_dates.count).to eq(2)

      expect(converted_accessions[0]['publish']).to be_truthy
      expect(converted_accessions[1]['publish']).to be_nil
      expect(converted_accessions[2]['publish']).to be_truthy
      expect(converted_accessions[3]['publish']).to be_nil

      expect(converted_events.count).to eq(26)

      converted_dates = converted_events.map { |e| e['date'] }.compact
      expect(converted_dates.count).to eq(26)
      expect(converted_dates.first['expression']).to eq('2001-01-22')

      notes = converted_events.map { |e| e['outcome_note'] }.compact
      expect(notes.count).to eq(6)
      expect(notes.last).to eq('TFY7B')

      notes = converted_events.map { |e| e['outcome_note'] }.compact
      expect(notes).not_to include('7YNN5')
    end
  end

  context 'when at least one accession provided in the CSV has an invalid date type' do
    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/accession_import_with_invalid_date_types.csv", File.dirname(__FILE__))
    end

    it "fails to convert records from the CSV and raises invalid date type error" do
      accessions_count_before = ::Accession.count

      expect do
        convert(csv_file)
      end.to raise_error do |error|
        expect(error).to be_a AccessionConverterInvalidDateTypeError
        expect(error.message).to eq 'Invalid date type provided: inclusive dates; must be one of: ["bulk", "inclusive", "single"]; Date provided: #<JSONModel(:date) {"jsonmodel_type"=>"date", "uri"=>nil, "label"=>"Creation", "expression"=>"ca. 2006-2008", "begin"=>"2006", "end"=>"2008", "date_type"=>"inclusive dates"}>;'

        accessions_count_after = ::Accession.count
        expect(accessions_count_before).to eq accessions_count_after
      end
    end
  end
end
