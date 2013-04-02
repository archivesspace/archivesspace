require 'spec_helper'

describe 'Reporting Engine' do
  
  it "can generate an unprocessed accessions report" do
    
    a = create(:json_accession)
    
    # response = @reporter.report_response(UnprocessedAccessionsReport.new({}), 'pdf')
    
    response = get "/reports/unprocessed_accessions?format=pdf"
    
    response.instance_variable_get(:@status).should eq(200)
    
  end 
  
  it "can escape html entities when generating an unprocessed accessions report" do
    
    a = create(:json_accession, :title => "This & That")
    
    # response = @reporter.report_response(UnprocessedAccessionsReport.new({}), 'pdf')
    
    response = get "/reports/unprocessed_accessions?format=pdf"
    
    response.instance_variable_get(:@status).should eq(200)
    
  end 
  
end