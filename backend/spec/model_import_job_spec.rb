require 'spec_helper'
require 'stringio'

describe 'Import job model' do

  let(:job) do
    json = build(:json_import_job)
    user = create_nobody_user
    ImportJob.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user)
  end

  it "can create an import job" do
    job.should_not be(nil)
  end


  it "can attach some input files to a job" do
    ImportJob.stub(:get_file_store) do
      double(:store => "stored_path")
    end

    job.add_file(StringIO.new)
    job.add_file(StringIO.new)

    job.job_files.map(&:file_path).should eq(["stored_path", "stored_path"])
  end


  it "can get the owner of a job" do
    job.owner.username.should eq("nobody")
  end


end
