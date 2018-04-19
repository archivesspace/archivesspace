require 'spec_helper'

describe 'ARKIdentifier model' do 

  it "creates a ARKIdentifier to a resource" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKIdentifer.create(:resource_id => resource[:id])

    expect(ARKIdentifer[ark[:id]].resource_id).to eq(resource[:id])
  end

  it "creates an ARKIdentifier to a digital_object" do
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)

    ark = ARKIdentifer.create(:digital_object_id => digital_object[:id])

    expect(ARKIdentifer[ark[:id]].digital_object_id).to eq(digital_object[:id])
  end

  it "creates an ARKIdentifier to an accession" do
    accession = create_accession

    ark = ARKIdentifer.create(:accession_id => accession[:id])

    expect(ARKIdentifer[ark[:id]].accession_id).to eq(accession[:id])
  end

  it "must specify at least one of resource, accession or digital object" do
    expect{ ark = ARKIdentifer.create }.to raise_error(Sequel::ValidationFailed)
  end

  it "cannot link to more than one type of resource" do
    resource = create_resource(:title => generate(:generic_title))
    accession = create_accession
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)

    expect{ ark = ARKIdentifer.create(:accession_id => accession[:id],
                                      :resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)

    expect{ ark = ARKIdentifer.create(:accession_id => accession[:id],
                                      :digital_object_id => digital_object[:id]) }.to raise_error(Sequel::ValidationFailed)

    expect{ ark = ARKIdentifer.create(:digital_object_id => digital_object[:id],
                                      :resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)

    expect{ ark = ARKIdentifer.create(:digital_object_id => digital_object[:id],
                                      :accession_id => accession[:id],
                                      :resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)   
  end

  it "must link to a unique resource" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKIdentifer.create(:resource_id => resource[:id])

    # first one creates successfully
    expect(ARKIdentifer[ark[:id]].resource_id).to eq(resource[:id])

    # duplicate raises validation exception
    expect{ ARKIdentifer.create(:resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)
  end

  it "must link to a unique accession" do
    accession = create_accession
    ark = ARKIdentifer.create(:accession_id => accession[:id])

     # first one creates successfully
    expect(ARKIdentifer[ark[:id]].accession_id).to eq(accession[:id])

    # duplicate raises validation exception
    expect{ ARKIdentifer.create(:accession_id => accession[:id]) }.to raise_error(Sequel::ValidationFailed)
  end

  it "must link to a unique digital_object" do
    json = build(:json_digital_object)
    digital_object = DigitalObject.create_from_json(json)
    ark = ARKIdentifer.create(:digital_object_id => digital_object[:id])

    # first one creates successfully
    expect(ARKIdentifer[ark[:id]].digital_object_id).to eq(digital_object[:id])

    # duplicate raises validation exception
    expect{ ARKIdentifer.create(:digital_object_id => digital_object[:id]) }.to raise_error(Sequel::ValidationFailed)
  end
end
