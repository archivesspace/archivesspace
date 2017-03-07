require 'spec_helper'

def find_and_replace_job(resource_uri)
  json = build(:json_job,
               :job_type => 'find_and_replace_job',
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

    job.should_not be(nil)
    job.job_type.should eq('find_and_replace_job')
    job.owner.username.should eq('nobody')
  end


  it "ensures that the target property exists in the target schema" do
    skip("this seems to not be working when run in the suite?") 
    resource1 = a_resource

    json = find_and_replace_job(resource1.uri)
    json.job['property'] = "WHATEVER"
    user = create_nobody_user

    expect {
      job = Job.create_from_json(json,
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

    Resource.to_jsonmodel(resource1.id).extents[0]['container_summary'].should eq('a box of bars')
    Resource.to_jsonmodel(resource2.id).extents[0]['container_summary'].should eq('a box of foos')
    ArchivalObject.to_jsonmodel(component1.id).extents[0]['container_summary'].should eq('a box of bars')
    ArchivalObject.to_jsonmodel(component2.id).extents[0]['container_summary'].should be_nil

    Resource.to_jsonmodel(resource1.id).extents[0]['last_modified_by'].should eq('nobody')
    Resource.to_jsonmodel(resource2.id).extents[0]['last_modified_by'].should eq('admin')

  end
end
