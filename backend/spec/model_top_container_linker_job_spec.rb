require 'spec_helper'

def top_container_linker_job(filepath)
    build(:json_job,
            :job_type => 'top_container_linker_job',
            :job => build(:json_top_container_linker_job,
              :filename => filepath.path))
end

describe "Top Container Linker job model" do

  let(:user) { create_nobody_user }
  let(:job) do
    tmp = ASUtils.tempfile("doc-#{Time.now.to_i}")
    tmp.write("foobar")
    tmp.rewind
            
        #tmpfile = File.join(File.dirname(__FILE__), 'testTopLinkerUpload.csv')
    json = top_container_linker_job(tmp)
    job = Job.create_from_json(json,
      :repo_id => $repo_id,
      :user => user )
    
    job.add_file(tmp)
    job
  end

  it "can create a top container linker job" do                          
    expect(job).not_to be_nil
    expect(job.job_type).to eq("top_container_linker_job")
    expect(job.owner.username).to eq('nobody')
    expect(job.job_files).not_to be_empty
  end
  
#  it "can be run and record the results" do
#      job_runner = JobRunner.for(job)
#      job_runner.run
#  
#      expect(job.created_records.count).to eq(1)
#      expect(job.created_records.first[:record_uri]).to match(/accessions\/\d+$/)
#      expect(Accession[JSONModel(:accession).id_for(job.created_records.first[:record_uri])].title).to eq('foobar')
#    end

end
