require 'spec_helper'

describe 'ARK Name controller' do
  it "should resolve a resource" do
    resource = create_resource(:title => generate(:generic_title))
    ArkName.create_from_resource(resource)

    ark = ArkName.first(:resource_id => resource.id)

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
    ArkName.create_from_archival_object(archival_object)

    ark = ArkName.first(:archival_object_id => archival_object.id)

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

end
