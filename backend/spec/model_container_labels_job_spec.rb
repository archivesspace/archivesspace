require 'spec_helper'

def container_labels_job(resource_uri)
  build(
    :json_job,
    :job => build(:json_container_labels_job, source: resource_uri)
  )
end

def create_resource_with_tree(opts = {})
  resource = create_resource

  parent = create(
    :json_archival_object,
    {
      :resource => {"ref" => resource.uri},
      :level => "series",
      :component_id => SecureRandom.hex
    }.merge(opts.fetch(:parent_properties, {}))
  )

  child = create(
    :json_archival_object,
    "resource" => {"ref" => resource.uri},
    "parent" => {"ref" => parent.uri},
    "instances" => [build(:json_instance)]
  )

  resource
end

describe "Container labels job model" do

  let(:user) { create_nobody_user }

  it "can create a container labels job" do
    opts = {:title => generate(:generic_title)}
    resource = create_resource_with_tree(opts)

    json = container_labels_job(resource.uri)
    job = Job.create_from_json(
      json,
      :repo_id => $repo_id,
      :user => user
    )

    jr = JobRunner.for(job)
    jr.run
    job.refresh

    expect(job).not_to be_nil
    expect(job.job_type).to eq("container_labels_job")
    expect(job.owner.username).to eq('nobody')
    expect(job.job_files.length).to eq(1)
  end

end
