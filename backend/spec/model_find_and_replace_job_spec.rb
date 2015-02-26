require 'spec_helper'
require_relative '../app/lib/find_and_replace'

describe 'Find and Replace job model' do

  before(:all) do

  end

  def a_resource
    create(:json_resource, :extents => [build(:json_extent, :container_summary => "a box of foos")])
  end

  def a_component(resource_uri)
    archival_object1 = create(:json_archival_object, :extents => [build(:json_extent, :container_summary => "a box of foos")], :resource => {:ref => resource_uri})
  end

  it "can create a find and replace job" do
    resource1 = a_resource

    json = build(:json_find_and_replace_job, 
                 :arguments => {:find => "/foo/", :replace => "bar"}, 
                 :scope => {
                   :jsonmodel_type => "extent",
                   :property => "container_summary",
                   :base_record_uri => resource1.uri
                 })

    user = create_nobody_user
    job = FindAndReplaceJob.create_from_json(json,
                                             :repo_id => $repo_id,
                                             :user => user)


    job.should_not be(nil)
  end


  it "ensurers that the target property exists in the target schema" do
    resource1 = a_resource

    json = build(:json_find_and_replace_job, 
                 :arguments => {:find => "/foo/", :replace => "bar"}, 
                 :scope => {
                   :jsonmodel_type => "extent",
                   :property => "WHATEVER",
                   :base_record_uri => resource1.uri
                 })

    user = create_nobody_user

    expect {
      job = FindAndReplaceJob.create_from_json(json,
                                               :repo_id => $repo_id,
                                               :user => user)
    }.to raise_error(JSONModel::ValidationException)
  end


  it "runs the job within the graph of scope.base_record" do
    resource1 = a_resource
    resource2 = a_resource
    component1 = a_component(resource1.uri)
    component2 = create(:json_archival_object, :extents => [build(:json_extent)], :resource => {:ref => resource1.uri})


    json = build(:json_find_and_replace_job, 
                 :arguments => {:find => "/foo/", :replace => "bar"}, 
                 :scope => {
                   :jsonmodel_type => "extent",
                   :property => "container_summary",
                   :base_record_uri => resource1.uri
                 })

    user = create_nobody_user
    job = FindAndReplaceJob.create_from_json(json,
                                             :repo_id => $repo_id,
                                             :user => user)


    job_runner = FindAndReplaceRunner.new(job)
    job_runner.run
    
    Resource.to_jsonmodel(resource1.id).extents[0]['container_summary'].should eq('a box of bars')
    Resource.to_jsonmodel(resource2.id).extents[0]['container_summary'].should eq('a box of foos')
    ArchivalObject.to_jsonmodel(component1.id).extents[0]['container_summary'].should eq('a box of bars')
    ArchivalObject.to_jsonmodel(component2.id).extents[0]['container_summary'].should be_nil

  end


  # finish method

  # it leaves a record of which records were updated?

  # find a case that causes a validation error?

  # back references?

end


describe "The Find and Replace Queue" do

  


end
