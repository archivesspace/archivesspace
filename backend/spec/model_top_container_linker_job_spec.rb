require 'spec_helper'

def top_container_linker_job(filepath)
    build(:json_job,
            :job_type => 'top_container_linker_job',
            :job => build(:json_top_container_linker_job,
              :filename => filepath.path, :content_type => 'text/csv', :resource_id => 1234))
end

describe "Top Container Linker job model" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
    
  let(:user) { create_nobody_user }
  

  it "can create a top container linker job" do 
    tmp = ASUtils.tempfile("doc-#{Time.now.to_i}")
    tmp.write("foobar")
    tmp.rewind
            
        #tmpfile = File.join(File.dirname(__FILE__), 'testTopLinkerUpload.csv')
    json = top_container_linker_job(tmp)
    job = Job.create_from_json(json,
      :repo_id => $repo_id,
      :user => user )
    
    job.add_file(tmp)
                         
    expect(job).not_to be_nil
    expect(job.job_type).to eq("top_container_linker_job")
    expect(job.owner.username).to eq('nobody')
    blob = ASUtils.json_parse(job.job_blob)
    expect(blob["content_type"]).to eq('text/csv')
    expect(job.job_files).not_to be_empty
    expect(blob["resource_id"]).to eq(1234)
  end
  
  it "can run the job" do
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00007'})
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00008'})
    create_archival_object({:title => generate(:generic_title), :ref_id => 'hua15019c00009'})
        
    tmpfilename = BULK_FIXTURES_DIR + '/testTopLinkerUpload.csv'
    tmpfile = File.open(tmpfilename)
    json = top_container_linker_job(tmpfile)
    job = Job.create_from_json(json,
      :repo_id => $repo_id,
      :user => user )
    
    job.add_file(tmpfile)

    jr = JobRunner.for(job)
    jr.run

    job.refresh
    tmpfile.close
    expect(job.job_files.length).to eq(1)
  end


end
