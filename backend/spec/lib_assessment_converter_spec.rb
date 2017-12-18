require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/assessment_converter'

describe 'Assessment converter' do

  def my_converter
    AssessmentConverter
  end

  let (:test_record) { create_accession }
  let (:test_user) { 'admin' }

  def with_sample_csv_file
    rows = CSV.parse(File.read(File.join(File.dirname(__FILE__), "../app/exporters/examples/assessment/aspace_assessment_import_template.csv")))

    headers = rows[1]
    data = rows[2..-1]

    test_dates = ['1/1/2000', '31/12/2005', '2000-01-01']

    data.each_with_index do |row, rownum|
      headers.each_with_index do |header, idx|
        if header == 'record'
          # Substitute our test record
          row[idx] = "accession_#{test_record.id}"
        elsif header == 'surveyed_by' || header == 'reviewer'
          # Substitute our test user
          row[idx] = test_user
        elsif ['survey_begin', 'survey_end'].include?(header)
          # Test a whacky excel date.  Set begin to end to avoid time-travel-related validation errors.
          row[idx] = test_dates[rownum % test_dates.length]
        end
      end
    end

    Tempfile.open('assessment_csv') do |tempfile|
      tempfile.write(CSV.generate {|csv|
                       rows.each do |row|
                         csv << row
                       end
                     })
      tempfile.flush

      yield headers, data, tempfile.path
    end
  end

  it "loads the sample CSV successfully" do
    with_sample_csv_file do |_headers, data, csv_path|
      records = convert( csv_path)

      # One record per CSV data row
      records.length.should eq(data.length)
    end
  end

  it "copes with interesting Excel dates" do
    with_sample_csv_file do |_headers, data, csv_path|
      records = convert(csv_path)
      records.each do |record|
        ['2005-12-31', '2000-01-01'].should include(record['survey_end'])
      end
    end
  end
end
