require 'spec_helper'

describe 'ASModel Object Graph' do

  it "can produce a simple object graph from a subject relationship" do
    resource = create(:resource, :repo_id => $repo_id)
    subject = Subject.create_from_json(build(:json_subject))

    relationship = Subject.find_relationship(:subject).relate(resource, subject, {
                                                                :aspace_relationship_position => 0,
                                                                :system_mtime => Time.now,
                                                                :user_mtime => Time.now
                                                              })


    resource.object_graph.models.length.should eq(2)

    resource.object_graph.each.
             map {|_, values| values}.
             flatten.
             sort.should eq([resource.id, relationship.id].sort)
  end


  it "can produce a simple object graph from a top-level tree" do
    resource = create(:resource, :repo_id => $repo_id)
    top_ao = create(:archival_object, :root_record_id => resource.id, :repo_id => $repo_id, :position => 0)

    count = 5

    count.times do
      ArchivalObject.create_from_json(build(:json_archival_object,
                                            :resource => {'ref' => resource.uri},
                                            :parent => {'ref' => top_ao.uri}))
    end

    resource.object_graph.each.map {|_, ids| ids.to_a}.flatten.length.should eq(count + 2)
    top_ao.object_graph.each.map {|_, ids| ids.to_a}.flatten.length.should eq(count + 1)
  end


  it "can produce a simple object graph including nested records" do
    resource = Resource.create_from_json(build(:json_resource,
                                               :extents => [build(:json_extent)]))

    resource.object_graph.each.map {|model, _| model}.include?(Extent).should be_truthy
  end



end
