require 'spec_helper'

describe 'ASModel Object Graph' do

  it "can produce a simple object graph from a subject relationship" do
    resource = Resource.create_from_json(build(:json_resource))
    subject = Subject.create_from_json(build(:json_subject))

    relationship = Subject.find_relationship(:subject).relate(resource, subject, {
                                                                :aspace_relationship_position => 0,
                                                                :system_mtime => Time.now,
                                                                :user_mtime => Time.now
                                                              })


    expect(resource.object_graph.models.length).to eq(2)

    expect(resource.object_graph.each.
             map {|_, values| values}.
             flatten.
             sort).to eq([resource.id, relationship.id].sort)
  end


  it "can produce a simple object graph from a top-level tree" do
    resource = Resource.create_from_json(build(:json_resource))
    top_ao = ArchivalObject.create_from_json(build(:json_archival_object))
    top_ao.root_record_id = resource.id
    top_ao.position = 0
    top_ao.save

    count = 5

    count.times do
      ArchivalObject.create_from_json(build(:json_archival_object,
                                            :dates => [],
                                            :extents => [],
                                            :resource => {'ref' => resource.uri},
                                            :parent => {'ref' => top_ao.uri}))
    end

    expect(resource.object_graph.each.map {|_, ids| ids.to_a}.flatten.length).to eq(count + 2)
    expect(top_ao.object_graph.each.map {|_, ids| ids.to_a}.flatten.length).to eq(count + 1)
  end


  it "can produce a simple object graph including nested records" do
    resource = Resource.create_from_json(build(:json_resource,
                                               :extents => [build(:json_extent)]))

    expect(resource.object_graph.each.map {|model, _| model}.include?(Extent)).to be_truthy
  end



end
