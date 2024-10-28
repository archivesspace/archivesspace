require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/location_converter'

describe 'Location converter' do

  def my_converter
    LocationConverter
  end

  let(:test_file) do
    test_file = File.expand_path(
      '../../backend/spec/examples/aspace_location_import_template.csv',
      File.dirname(__FILE__)
    )
  end

  it 'creates one location record for each row in the CSV file' do
    locations = convert(test_file).select {|r| r['jsonmodel_type'] == 'location' }
    expect(locations.count).to eq(3)
  end

  context 'when import repository is not checked' do
    before do
      my_converter.instance_variable_set(:@import_options, {})
    end

    it 'creates location records without owner repo' do
      locations = convert(test_file).select {|r| r['jsonmodel_type'] == 'location' }
      expect(locations.select { |l| l['owner_repo'] }).to be_empty
    end
  end

  context 'when import repository is checked' do
    before do
      my_converter.instance_variable_set(:@import_options, {:import_repository => true})
    end

    it 'creates location records with owner repo' do
      locations = convert(test_file).select {|r| r['jsonmodel_type'] == 'location' }
      expect(locations.select { |l| l['owner_repo'] }).not_to be_empty
    end
  end

end
