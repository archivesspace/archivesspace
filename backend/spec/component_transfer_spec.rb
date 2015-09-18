require 'spec_helper'

describe "Resource Component Transfer Endpoint" do

  before(:each) do
    @resource_alpha = create(:json_resource)
    @resource_beta = create(:json_resource)
  end

  def transfer(resource, object)
    uri = "/repositories/#{$repo_id}/component_transfers"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data({"target_resource" => resource.uri, "component" => object.uri})

    response = JSONModel::HTTP.do_http_request(url, request)

    response
  end


  it "can move an archival object from one resource tree to another" do

    object = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri})

    object.resource['ref'].should eq(@resource_alpha.uri)

    response = transfer(@resource_beta, object)

    response.code.should eq('200')

    refreshed_object = JSONModel(:archival_object).find(object.id)

    refreshed_object.resource['ref'].should eq(@resource_beta.uri)

    JSONModel(:resource_tree).find(nil, :resource_id => @resource_beta.id).children.length.should eq(1)

  end


  it "returns a 404 response code when asked to transfer a non-existent object" do

    fake_uri = JSONModel(:archival_object).uri_for(99*99)

    response = transfer(@resource_alpha, build(:json_archival_object, :uri => fake_uri))

    response.code.should eq('404')
    response.body.should match(/That which does not exist cannot be moved/)
  end


  it "returns a 400 response code when asked to transfer an object to a resource containing a conflicting object" do

    conflicting_ref_id = generate(:alphanumstr)

    object_alpha = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri}, :ref_id => conflicting_ref_id)
    object_beta = create(:json_archival_object, :resource => {:ref => @resource_beta.uri}, :ref_id => conflicting_ref_id)

    response = transfer(@resource_beta, object_alpha)

    response.code.should eq('400')
    response.body.should match (/unique to its resource/)
  end


  it "moves children of the component it's moving" do

    parent = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri})
    child = create(:json_archival_object, :parent => {:ref => parent.uri}, :resource => {:ref => @resource_alpha.uri})

    transfer(@resource_beta, parent)

    JSONModel(:archival_object).find(child.id).resource['ref'].should eq(@resource_beta.uri)

  end


  it "can move objects that aren't at the root of the tree" do

    parent = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri})
    child = create(:json_archival_object, :parent => {:ref => parent.uri}, :resource => {:ref => @resource_alpha.uri})

    transfer(@resource_beta, child)

    JSONModel(:archival_object).find(child.id).resource['ref'].should eq(@resource_beta.uri)

    tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource_beta.id)

    tree.children.length.should eq(1)
  end

  it "can move objects to the next available spot in the tree" do

    parent = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri})
    child = create(:json_archival_object, :parent => {:ref => parent.uri}, :resource => {:ref => @resource_alpha.uri})

    transfer(@resource_beta, child).code.should eq('200')
    transfer(@resource_beta, parent).code.should eq('200')

    tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource_beta.id)

    tree.children.length.should eq(2)
  end


  it "creates an Event to mark the transfer" do
    archival_object = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri})

    response = transfer(@resource_beta, archival_object)
    transfer_result = ASUtils.json_parse(response.body)

    event = JSONModel(:event).find_by_uri(transfer_result['event'])

    event.event_type.should eq("component_transfer")
    event.linked_records.length.should eq(3)
    event.linked_records.select{|link| link["role"] === "source"}.first["ref"].should eq(@resource_alpha.uri)
    event.linked_records.select{|link| link["role"] === "outcome"}.first["ref"].should eq(@resource_beta.uri)
    event.linked_records.select{|link| link["role"] === "transfer"}.first["ref"].should eq(archival_object.uri)
  end


  it "doesn't break node sequencing" do
    parent = create(:json_archival_object, :resource => {:ref => @resource_alpha.uri})
    children = []
    10.times {
      children << create(:json_archival_object, :parent => {:ref => parent.uri}, :resource => {:ref => @resource_alpha.uri})
    }

    # Now transfer
    transfer(@resource_beta, parent)

    first_child = JSONModel(:archival_object).find(children.first.id)
    last_child = JSONModel(:archival_object).find(children.last.id)

    last_child.position.should eq(9)

    first_child.title = "something else"

    expect {
      ArchivalObject[first_child.id].update_from_json(first_child)
    }.to_not raise_error

    expect {
      ArchivalObject[last_child.id].update_from_json(last_child)
    }.to_not raise_error

    last_child.position.should eq(9)
  end
end
