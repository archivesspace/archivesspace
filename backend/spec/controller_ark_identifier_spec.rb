require 'spec_helper'

describe 'ARK Identifier controller' do
  it "should redirecto to resource" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKIdentifier.first(:resource_id => resource.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
    resource.delete
  end

  
  it "should redirect to accession" do
    accession = create_accession
    ark = ARKIdentifier.first(:accession_id => accession.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
    accession.delete
  end

  it "should redirect to digital object" do
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)
    ark = ARKIdentifier.first(:digital_object_id => digital_object.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
    digital_object.delete
  end

  it "should return 404 if ark_id not found" do
    get "/ark:/f00001/42"
    expect(last_response.status).to eq(404)
  end

  it "should redirect to external_ark_url in resource if defined" do
    resource = create_resource(:title => generate(:generic_title),
                               :external_ark_url => "http://foo.bar/ark:/123/123")
    ark = ARKIdentifier.first(:resource_id => resource.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
    expect(last_response.location).to eq("http://foo.bar/ark:/123/123")

    resource.delete
  end

  it "should redirect to external_ark_url in accession if defined" do
    accession = create_accession(:external_ark_url => "http://foo.bar/ark:/123/123")
    ark = ARKIdentifier.first(:accession_id => accession.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
    expect(last_response.location).to eq("http://foo.bar/ark:/123/123")

    accession.delete
  end

  it "should redirect to external_ark_url in digital_object if defined" do
    json = build(:json_digital_object, {:external_ark_url => "http://foo.bar/ark:/123/123" })
    digital_object = DigitalObject.create_from_json(json)
    ark = ARKIdentifier.first(:digital_object_id => digital_object.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
    expect(last_response.location).to eq("http://foo.bar/ark:/123/123")

    digital_object.delete
  end
end
