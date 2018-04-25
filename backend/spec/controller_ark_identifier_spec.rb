require 'spec_helper'

describe 'ARK Identifier controller' do
  it "should redirecto to resource" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKIdentifer.first(:resource_id => resource.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
  end

  
  it "should redirect to accession" do
    accession = create_accession
    ark = ARKIdentifer.first(:accession_id => accession.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
  end

  it "should redirect to digital object" do
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)
    ark = ARKIdentifer.first(:digital_object_id => digital_object.id)

    get "/ark:/f00001/#{ark.id}"
    expect(last_response.status).to eq(302)
  end

  it "should return 404 if ark_id not found" do
    get "/ark:/f00001/42"
    expect(last_response.status).to eq(404)
  end
end
