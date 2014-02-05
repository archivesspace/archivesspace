require 'spec_helper'

describe 'Record Suppression' do

  it "can suppress an accession record" do
    accession = create_accession
    accession.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      Accession.this_repo[accession.id].should eq(nil)
    end
  end


  it "can suppress a resource record" do
    resource = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    resource.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      Resource.this_repo[resource.id].should eq(nil)
    end
  end


  it "can suppress an archival object record" do
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object), :repo_id => $repo_id)
    archival_object.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      ArchivalObject.this_repo[archival_object.id].should eq(nil)
    end
  end


  it "can suppress an digital object record" do
    digital_object = DigitalObject.create_from_json(build(:json_digital_object), :repo_id => $repo_id)
    digital_object.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      DigitalObject.this_repo[digital_object.id].should eq(nil)
    end
  end


  it "can suppress an digital object component record" do
    digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component), :repo_id => $repo_id)
    digital_object_component.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      DigitalObjectComponent.this_repo[digital_object_component.id].should eq(nil)
    end
  end


  it "will suppress the child archival object of a suppressed resource" do
    resource = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => resource.uri}), :repo_id => $repo_id)

    resource.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      ArchivalObject.this_repo[archival_object.id].should eq(nil)
    end
  end


  it "will suppress the child archival object of a suppressed parent" do
    resource = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    archival_object_parent = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => resource.uri}), :repo_id => $repo_id)
    archival_object_child = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => resource.uri}, :parent => {:ref => archival_object_parent.uri}), :repo_id => $repo_id)

    archival_object_parent.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      ArchivalObject.this_repo[archival_object_child.id].should eq(nil)
    end
  end


  it "will suppress the child digital object component of a suppressed digital object" do
    digital_object = DigitalObject.create_from_json(build(:json_digital_object), :repo_id => $repo_id)
    digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}), :repo_id => $repo_id)

    digital_object.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      DigitalObjectComponent.this_repo[digital_object_component.id].should eq(nil)
    end
  end

  it "will suppress the child digital object component of a suppressed parent" do
    digital_object = DigitalObject.create_from_json(build(:json_digital_object), :repo_id => $repo_id)
    digital_object_component_parent = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}), :repo_id => $repo_id)
    digital_object_component_child = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}, :parent => {:ref => digital_object_component_parent.uri}), :repo_id => $repo_id)

    digital_object_component_parent.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      DigitalObjectComponent.this_repo[digital_object_component_child.id].should eq(nil)
    end
  end

end