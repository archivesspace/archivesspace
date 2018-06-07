require 'spec_helper'

describe 'ARKIdentifier model' do 

  it "creates a ARKIdentifier to a resource when a resource is created" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKIdentifier.where(:resource_id => resource[:id]).first

    expect(ARKIdentifier[ark[:id]].resource_id).to eq(resource[:id])
  end

  it "creates an ARKIdentifier to a digital_object" do
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)
    ark = ARKIdentifier.where(:digital_object_id => digital_object[:id]).first

    expect(ARKIdentifier[ark[:id]].digital_object_id).to eq(digital_object[:id])
  end

  it "creates an ARKIdentifier to an accession" do
    accession = create_accession
    ark = ARKIdentifier.where(:accession_id => accession[:id]).first

    expect(ARKIdentifier[ark[:id]].accession_id).to eq(accession[:id])
  end

  it "must specify at least one of resource, accession or digital object" do
    expect{ ark = ARKIdentifier.create }.to raise_error(Sequel::ValidationFailed)
  end

  it "cannot link to more than one type of resource" do
    resource = create_resource(:title => generate(:generic_title))
    accession = create_accession
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)

    # delete the auto created ARKIdentifiers for text
    ARKIdentifier.where(:resource_id => resource.id).delete
    ARKIdentifier.where(:digital_object_id => digital_object.id).delete
    ARKIdentifier.where(:accession_id => accession.id).delete


    expect{ ark = ARKIdentifier.create(:accession_id => accession[:id],
                                      :resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)

    expect{ ark = ARKIdentifier.create(:accession_id => accession[:id],
                                      :digital_object_id => digital_object[:id]) }.to raise_error(Sequel::ValidationFailed)

    expect{ ark = ARKIdentifier.create(:digital_object_id => digital_object[:id],
                                      :resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)

    expect{ ark = ARKIdentifier.create(:digital_object_id => digital_object[:id],
                                      :accession_id => accession[:id],
                                      :resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)   
  end

  it "must link to a unique resource" do
    # ARK is created with resource
    resource = create_resource(:title => generate(:generic_title))

    # duplicate raises validation exception
    expect{ ARKIdentifier.create(:resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)
  end

  it "must link to a unique accession" do
    # ARK is created with accession
    accession = create_accession

    # duplicate raises validation exception
    expect{ ARKIdentifier.create(:accession_id => accession[:id]) }.to raise_error(Sequel::ValidationFailed)
  end

  it "must link to a unique digital_object" do
    # ARK is created with digital object
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)

    # duplicate raises validation exception
    expect{ ARKIdentifier.create(:digital_object_id => digital_object[:id]) }.to raise_error(Sequel::ValidationFailed)
  end
end
