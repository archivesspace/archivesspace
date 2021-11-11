require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/accession_converter'

describe 'Accession converter' do

  def my_converter
    AccessionConverter
  end


  before(:all) do
    test_file = File.expand_path("../../templates/aspace_accession_import_template.csv",
                                 File.dirname(__FILE__))

    @records = convert(test_file)
    @accessions = @records.select {|r| r['jsonmodel_type'] == 'accession' }
    @agents = @records.select { |a| a['jsonmodel_type'].include?('agent_') }
    @subjects = @records.select { |a| a['jsonmodel_type'] == 'subject' }
    @events = @records.select { |a| a['jsonmodel_type'] == 'event' }
    @dates = []
    @accessions.each { |a| @dates = @dates + a['dates'] }
  end

  it "created one Accession record for each row in the CSV file" do
    expect(@accessions.count).to eq(10)
  end

  it "created a  Agent record if one is in the row" do
    expect(@agents.count).to eq(5)
  end

  it "creates an Agent contact subrecord with telephone and fax if in the row" do
    telephones = @agents.first['agent_contacts'].map { |c| c['telephones'] }.flatten
    expect(telephones.count).to eq(2)
    expect(telephones[0]['number_type']).to eq('fax')
    expect(telephones[0]['number']).to eq('999-444-4444')
    expect(telephones[1]['number_type']).to eq('home')
    expect(telephones[1]['ext']).to eq('247')
  end

  it "created a Subject record if one is in the row" do
    expect(@subjects.count).to eq(8)
  end

  it "created a Date record if one is in the row" do
    expect(@dates.count).to eq(2)
  end

  it "sets the publish status correctly" do
    expect(@accessions[0]['publish']).to be_truthy
    expect(@accessions[1]['publish']).to be_nil
    expect(@accessions[2]['publish']).to be_truthy
    expect(@accessions[3]['publish']).to be_nil
  end

  it "creates Event records if boolean is true" do
    expect(@events.count).to eq(26)
  end

  it "creates Event record dates if boolean is true" do
    dates = @events.map { |e| e['date'] }.compact
    expect(dates.count).to eq(26)
    expect(dates.first['expression']).to eq('2001-01-22')
  end

  it "creates Event outcome note if one is in the row and accession_cataloged boolean is true" do
    notes = @events.map { |e| e['outcome_note'] }.compact
    expect(notes.count).to eq(6)
    expect(notes.last).to eq('TFY7B')
  end

  it "does not create Event outcome note if one is in the row but boolean is false" do
    notes = @events.map { |e| e['outcome_note'] }.compact
    expect(notes).not_to include('7YNN5')
  end

end
