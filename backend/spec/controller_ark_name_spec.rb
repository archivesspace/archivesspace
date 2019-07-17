require 'spec_helper'

describe 'ARK Name controller' do
  it "should resolve a resource" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKName.first(:resource_id => resource.id)

    get "/ark:/f00001/#{ark.id}"
    response_hash = JSON.parse(last_response.body)

    expect(response_hash["id"]).to eq(resource.id)
    expect(response_hash["repo_id"]).to eq(resource.repo_id)
    expect(response_hash["type"]).to eq("Resource")

    resource.delete
  end

  it "should redirect to archival object" do
    json = build(:json_archival_object)
    archival_object = ArchivalObject.create_from_json(json)
    ark = ARKName.first(:archival_object_id => archival_object.id)

    get "/ark:/f00001/#{ark.id}"
    response_hash = JSON.parse(last_response.body)

    expect(response_hash["id"]).to eq(archival_object.id)
    expect(response_hash["repo_id"]).to eq(archival_object.repo_id)
    expect(response_hash["type"]).to eq("ArchivalObject")

    archival_object.delete
  end

  it "should return 404 if ark_id not found" do
    get "/ark:/f00001/42"

    response_hash = JSON.parse(last_response.body)
    expect(response_hash["type"]).to eq("not_found")
  end

  it "should redirect to external_ark_url in resource if defined" do
    resource = create_resource(:title => generate(:generic_title),
                               :external_ark_url => "http://foo.bar/ark:/123/123")
    ark = ARKName.first(:resource_id => resource.id)

    get "/ark:/f00001/#{ark.id}"
    response_hash = JSON.parse(last_response.body)

    expect(response_hash["type"]).to eq("external")
    expect(response_hash["external_url"]).to eq(resource.external_ark_url)

    resource.delete
  end

  it "should redirect to external_ark_url in archival_object if defined" do
    json = build(:json_archival_object, {:external_ark_url => "http://foo.bar/ark:/123/123" })
    archival_object = ArchivalObject.create_from_json(json)
    ark = ARKName.first(:archival_object_id => archival_object.id)

    get "/ark:/f00001/#{ark.id}"
    response_hash = JSON.parse(last_response.body)

    expect(response_hash["type"]).to eq("external")
    expect(response_hash["external_url"]).to eq(archival_object.external_ark_url)

    archival_object.delete
  end

end
