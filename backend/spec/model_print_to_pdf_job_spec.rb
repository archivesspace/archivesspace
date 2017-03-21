require 'spec_helper'

def print_to_pdf_job( resource_uri )
     build( :json_job, 
            :job => build(:json_print_to_pdf_job, :source => resource_uri)
          )
end

describe "Print to PDF job model" do

  let(:user) { create_nobody_user } 

  it "can create a print to pdf job" do
    opts = {:title => generate(:generic_title)}
    resource = create_resource(opts)
    
    json = print_to_pdf_job(resource.uri)
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user )
    
    job.should_not be(nil) 
    job.job_type.should eq("print_to_pdf_job")
    job.owner.username.should eq('nobody')
  end

  it "can create a pdf from a published resource" do
    opts = {:title => generate(:generic_title), :publish => true}
    resource = create_resource(opts)
    
    json = print_to_pdf_job(resource.uri)
    job = Job.create_from_json( json,
                               :repo_id => $repo_id,
                               :user => user )
    jr = JobRunner.for(job) 
    jr.run

    job.refresh
    job.job_files.length.should eq(1)
  end

  it "will create a pdf from an unpublished resource" do
    opts = {:title => generate(:generic_title), :publish => false}
    resource = create_resource(opts)

    json = print_to_pdf_job(resource.uri)
    job = Job.create_from_json( json,
                                :repo_id => $repo_id,
                                :user => user )
    jr = JobRunner.for(job)
    jr.run

    job.refresh
    job.job_files.length.should eq(1)
  end

end
