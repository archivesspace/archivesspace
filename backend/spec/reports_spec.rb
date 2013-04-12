require 'spec_helper'

describe 'Reporting Engine' do
  before(:each) do
    make_test_repo
  end

  it "can generate an unprocessed accessions report" do

    a = create(:json_accession)

    response = get "/repositories/#{@repo_id}/reports/unprocessed_accessions?format=pdf"

    response.instance_variable_get(:@status).should eq(200)
    
  end 
  
  it "can escape html entities when generating an unprocessed accessions report" do

    a = create(:json_accession, :title => "This & That")

    response = get "/repositories/#{@repo_id}/reports/unprocessed_accessions?format=pdf"

    response.instance_variable_get(:@status).should eq(200)

  end 
  
end