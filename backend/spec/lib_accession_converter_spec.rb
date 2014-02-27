require 'spec_helper'
require_relative '../app/converters/accession_converter'

describe 'Accession converter' do

  def convert_test_file
    test_file = File.expand_path("../app/exporters/examples/accession/test_accession.csv",
                                 File.dirname(__FILE__))

    converter = AccessionConverter.instance_for('accession_csv', test_file)
    converter.run
    JSON(IO.read(converter.get_output_path))
  end

  before(:all) do
    @records = convert_test_file
    @accessions = @records.select {|r| r['jsonmodel_type'] == 'accession' }
  end


  it "created one Accession record for each row in the CSV file" do
    @accessions.count.should eq(10)
  end


  it "maps accession_processing_started_date to collection_management.processing_started_date" do    
    @accessions[1]['collection_management']['processing_started_date'].should match(/\d{4}-\d{2}-\d{2}/)
  end
    
end

