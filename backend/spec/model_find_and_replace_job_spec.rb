require 'spec_helper'

def find_and_replace_job(resource_uri)
  json = build(:json_job,
               :job => build(:json_find_and_replace_job,
                             :find => "/foo/",
                             :replace => "bar",
                             :record_type => "extent",
                             :property => "container_summary",
                             :base_record_uri => resource_uri
                             )
               )

  json
end

def a_resource
  create(:json_resource, :extents => [build(:json_extent, :container_summary => "a box of foos")])
end


describe 'Find and Replace job model' do

  def a_component(resource_uri)
    archival_object1 = create(:json_archival_object, :extents => [build(:json_extent, :container_summary => "a box of foos")], :resource => {:ref => resource_uri})
  end

  it "can create a find and replace job" do
    resource1 = a_resource

    json = find_and_replace_job(resource1.uri)

    user = create_nobody_user
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user)

    expect(job).not_to be_nil
    expect(job.job_type).to eq('find_and_replace_job')
    expect(job.owner.username).to eq('nobody')
  end


  it "ensures that the target property exists in the target schema" do
    resource1 = a_resource

    json = find_and_replace_job(resource1.uri)
    json.job['property'] = "NON-EXISTENT-PROPERTY!!!"
    user = create_nobody_user

    expect {
      Job.create_from_json(json,
                           :repo_id => $repo_id,
                           :user => user)
    }.to raise_error(JSONModel::ValidationException)
  end


  it "runs the find and replacejob within the graph of scope.base_record" do
    resource1 = a_resource
    resource2 = a_resource
    component1 = a_component(resource1.uri)
    component2 = create(:json_archival_object, :extents => [build(:json_extent)], :resource => {:ref => resource1.uri})

    json = find_and_replace_job(resource1.uri)

    user = create_nobody_user
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user)


    job_runner = JobRunner.for(job)
    job_runner.run

    expect(Resource.to_jsonmodel(resource1.id).extents[0]['container_summary']).to eq('a box of bars')
    expect(Resource.to_jsonmodel(resource2.id).extents[0]['container_summary']).to eq('a box of foos')
    expect(ArchivalObject.to_jsonmodel(component1.id).extents[0]['container_summary']).to eq('a box of bars')
    expect(ArchivalObject.to_jsonmodel(component2.id).extents[0]['container_summary']).to be_nil

    expect(Resource.to_jsonmodel(resource1.id).extents[0]['last_modified_by']).to eq('nobody')
    expect(Resource.to_jsonmodel(resource2.id).extents[0]['last_modified_by']).to eq('admin')

  end
end
