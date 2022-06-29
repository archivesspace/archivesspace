require 'spec_helper'

def ns2_remover_job(dry_run = false)
  build(
    :json_job,
    :job_type => 'ns2_remover_job',
    :job => build(:json_ns2_remover_job, dry_run: dry_run)
  )
end

def create_messy_note
  content =<<~CONTENT
    <p>I am a <extref ns2:actuate="onRequest" ns2:show="new" 
    ns2:title="oh no" ns2:href="http://example.com/">bad, bad note</extref>.<p>
  CONTENT
  note = build(:json_note_bibliography,
    :content => [content],
    :persistent_id => "123456")

  note
end

describe "ns2 remover job model" do

  let(:user) { create_nobody_user }
  let(:resource) {
    create(:json_resource, {
           :notes => [create_messy_note] })
  }

  it "can create a ns2 remover job" do
    json = ns2_remover_job
    job = Job.create_from_json(
      json,
      :repo_id => $repo_id,
      :user => user
    )

    jr = JobRunner.for(job)
    jr.run
    job.refresh

    expect(job).not_to be_nil
    expect(job.job_type).to eq('ns2_remover_job')
    expect(job.owner.username).to eq('nobody')
  end

  it "deletes 'ns2:' strings in notes" do
    expect(Resource.to_jsonmodel(resource.id).notes[0]['content']).to include(/ ns2:/)

    json = ns2_remover_job
    job = Job.create_from_json(
      json,
      :repo_id => $repo_id,
      :user => user
    )

    jr = JobRunner.for(job)
    jr.run
    job.refresh

    expect(Resource.to_jsonmodel(resource.id).notes[0]['content']).not_to include(/ ns2:/)
  end

  it "won't delete 'ns2:' strings in notes when running dry run" do
    expect(Resource.to_jsonmodel(resource.id).notes[0]['content']).to include(/ ns2:/)

    json = ns2_remover_job(true)
    job = Job.create_from_json(
      json,
      :repo_id => $repo_id,
      :user => user
    )

    jr = JobRunner.for(job)
    jr.run
    job.refresh

    expect(Resource.to_jsonmodel(resource.id).notes[0]['content']).to include(/ ns2:/)
  end

end
