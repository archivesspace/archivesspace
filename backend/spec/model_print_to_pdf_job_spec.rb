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

    expect(job).not_to be_nil
    expect(job.job_type).to eq("print_to_pdf_job")
    expect(job.owner.username).to eq('nobody')
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
    expect(job.job_files.length).to eq(1)
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
    expect(job.job_files.length).to eq(1)
  end

end
