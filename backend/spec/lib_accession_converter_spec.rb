require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/accession_converter'

describe 'Accession converter' do
  let(:my_converter) {
    AccessionConverter
  }

  let(:test_file) {
    File.expand_path("../app/exporters/examples/accession/test_accession.csv",
                     File.dirname(__FILE__))
  }


  before(:all) do
    @records = convert(test_file)
    @accessions = @records.select {|r| r['jsonmodel_type'] == 'accession' }
  end


  it "created one Accession record for each row in the CSV file" do
    @accessions.count.should eq(10)
  end


  it "maps accession_processing_started_date to collection_management.processing_started_date" do    
    @accessions[1]['collection_management']['processing_started_date'].should match(/\d{4}-\d{2}-\d{2}/)
  end
    
end

