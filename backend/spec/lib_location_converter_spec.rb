require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/location_converter'

describe 'Location converter' do

  def my_converter
    LocationConverter
  end

  before(:all) do
    test_file = File.expand_path(
      '../../backend/spec/examples/aspace_location_import_template.csv',
      File.dirname(__FILE__)
    )
    @records = convert(test_file)
    @locations = @records.select {|r| r['jsonmodel_type'] == 'location' }
  end

  it 'created one Location record for each row in the CSV file' do
    expect(@locations.count).to eq(3)
  end

end
