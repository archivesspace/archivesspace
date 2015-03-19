require 'spec_helper'
require 'export_ead_spec_helper'
require_relative '../app/lib/print_to_pdf_runner'
require_relative '../app/lib/background_job_queue'

include ExportEADSpecHelper

def print_to_pdf_job( resource_uri )
     build( :json_job, 
            :job_type => 'print_to_pdf_job',
            :job => build(:json_print_to_pdf_job, :source => resource_uri)
          )
end

describe "Print to PDF job model" do
  let (:user) { create_nobody_user }

  before(:all) do
    
    as_test_user("admin") do 
      DB.open(true) { load_export_fixtures } 
    end
    
  end
  
  
  it "can create a print to pdf job" do
    json = print_to_pdf_job(@resource.uri)
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user )
    
    job.should_not be(nil) 
    job.job_type.should eq("print_to_pdf_job")
    job.owner.username.should eq('nobody')
  end

  it "can create a pdf from a resource" do
    json = print_to_pdf_job(@resource.uri)
    
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user )
    jr = JobRunner.for(job) 
    jr.run

  end
  


end
