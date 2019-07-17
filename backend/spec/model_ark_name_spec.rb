require 'spec_helper'

describe 'ARKName model' do

  it "creates a ARKName to a resource when a resource is created" do
    resource = create_resource(:title => generate(:generic_title))
    ark = ARKName.where(:resource_id => resource[:id]).first

    expect(ARKName[ark[:id]].resource_id).to eq(resource[:id])

    resource.delete
  end

  it "creates an ARKName to an archival object" do
    ao = ArchivalObject.create_from_json(
      build(
        :json_archival_object,
        :title => 'A new archival object'
      ),
      :repo_id => $repo_id)

    ark = ARKName.where(:archival_object_id => ao[:id]).first

    expect(ARKName[ark[:id]].archival_object_id).to eq(ao[:id])

    ao.delete
  end

  it "must specify at least one of resource or archival object" do
    expect{ ark = ARKName.create }.to raise_error(Sequel::ValidationFailed)
  end


  it "cannot link to more than one type of resource" do
    resource = create_resource(:title => generate(:generic_title))
    ao = ArchivalObject.create_from_json(
      build(
           :json_archival_object,
           :title => 'A new archival object'
           ),
     :repo_id => $repo_id)

    # delete the auto created ARKNames for test
    ARKName.where(:resource_id => resource.id).delete
    ARKName.where(:archival_object_id => ao.id).delete

    expect{ ark = ARKName.create(:resource_id => resource[:id],
                                       :archival_object_id => ao[:id] )}.to raise_error(Sequel::ValidationFailed)
  end

  it "must link to a unique resource" do
    # ARK is created with resource
    resource = create_resource(:title => generate(:generic_title))

    # duplicate raises validation exception
    expect{ ARKName.create(:resource_id => resource[:id]) }.to raise_error(Sequel::ValidationFailed)

    resource.delete
  end

  it "must link to a unique archival_object" do
    # ARK is created with archival_object
    ao = ArchivalObject.create_from_json(
      build(
           :json_archival_object,
           :title => 'A new archival object'
           ),
     :repo_id => $repo_id)


    # duplicate raises validation exception
    expect{ ARKName.create(:archival_object_id => ao[:id]) }.to raise_error(Sequel::ValidationFailed)

    ao.delete
  end

  it "creates an ARK url for resource" do
    opts = {:title => generate(:generic_title)}
    resource = create_resource(opts)
    ark = ARKName.first(:resource_id => resource.id)

    expect(ARKName::get_ark_url(resource.id, :resource)).to eq("#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}")

    resource.delete
  end

  it "creates an ARK url for archival_object" do
    ao = ArchivalObject.create_from_json(
      build(
        :json_archival_object,
        :title => 'A new archival object'
      ),
      :repo_id => $repo_id)

    ark = ARKName.first(:archival_object_id => ao.id)

    expect(ARKName::get_ark_url(ao.id, :archival_object)).to eq("#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}")

    ao.delete
  end

  it "get_ark_url returns external_ark_url if defined on the resource" do
    external_ark_url = "http://foo.bar/ark:/123/123"
    opts = {:title => generate(:generic_title),
                      external_ark_url: external_ark_url}
    resource = create_resource(opts)
    ark = ARKName.first(:resource_id => resource.id)

    expect(ARKName::get_ark_url(resource.id, :resource)).to eq("http://foo.bar/ark:/123/123")

    resource.delete
  end

  it "get_ark_url returns external_ark_url if defined on the archival object" do
    external_ark_url = "http://foo.bar/ark:/123/123"

    ao = ArchivalObject.create_from_json(
      build(
        :json_archival_object,
        :title => 'A new archival object',
        :external_ark_url => external_ark_url
      ),
      :repo_id => $repo_id)

    ark = ARKName.first(:archival_object_id => ao.id)

    expect(ARKName::get_ark_url(ao.id, :archival_object)).to eq("http://foo.bar/ark:/123/123")

    ao.delete
  end

end
