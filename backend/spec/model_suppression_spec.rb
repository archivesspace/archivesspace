require 'spec_helper'

describe 'Record Suppression' do

  it "can suppress an accession record" do
    accession = create_accession
    accession.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(Accession.this_repo[accession.id]).to be_nil
    end
  end


  it "can suppress a resource record" do
    resource = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    resource.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(Resource.this_repo[resource.id]).to be_nil
    end
  end

  it "can suppress an accession and then unsuppress it" do
    accession = create_accession

    accession.set_suppressed(true)

    create_nobody_user

    as_test_user('nobody') do
      expect(Accession.this_repo[accession.id]).to be_nil
    end

    accession.set_suppressed(false)

    as_test_user('nobody') do
      expect(Accession.this_repo[accession.id]).not_to be_nil
    end
  end


  it "can suppress an archival object record" do
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object), :repo_id => $repo_id)
    archival_object.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(ArchivalObject.this_repo[archival_object.id]).to be_nil
    end
  end


  it "doesn't show suppressed accessions when listing" do
    3.times do
      create_accession
    end

    create_nobody_user

    accession = create_accession
    accession.set_suppressed(true)

    as_test_user('nobody') do
      expect(Accession.this_repo.all.count).to eq(3)
    end
  end


  it "can suppress an digital object record" do
    digital_object = DigitalObject.create_from_json(build(:json_digital_object), :repo_id => $repo_id)
    digital_object.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(DigitalObject.this_repo[digital_object.id]).to be_nil
    end
  end


  it "can suppress an digital object component record" do
    digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component), :repo_id => $repo_id)
    digital_object_component.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(DigitalObjectComponent.this_repo[digital_object_component.id]).to be_nil
    end
  end


  it "will suppress the child archival object of a suppressed resource" do
    resource = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => resource.uri}), :repo_id => $repo_id)

    resource.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(ArchivalObject.this_repo[archival_object.id]).to be_nil
    end
  end


  it "will suppress the child archival object of a suppressed parent" do
    resource = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    archival_object_parent = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => resource.uri}), :repo_id => $repo_id)
    archival_object_child = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => resource.uri}, :parent => {:ref => archival_object_parent.uri}), :repo_id => $repo_id)

    archival_object_parent.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(ArchivalObject.this_repo[archival_object_child.id]).to be_nil
    end
  end


  it "will suppress the child digital object component of a suppressed digital object" do
    digital_object = DigitalObject.create_from_json(build(:json_digital_object), :repo_id => $repo_id)
    digital_object_component = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}), :repo_id => $repo_id)

    digital_object.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(DigitalObjectComponent.this_repo[digital_object_component.id]).to be_nil
    end
  end

  it "will suppress the child digital object component of a suppressed parent" do
    digital_object = DigitalObject.create_from_json(build(:json_digital_object), :repo_id => $repo_id)
    digital_object_component_parent = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}), :repo_id => $repo_id)
    digital_object_component_child = DigitalObjectComponent.create_from_json(build(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}, :parent => {:ref => digital_object_component_parent.uri}), :repo_id => $repo_id)

    digital_object_component_parent.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      expect(DigitalObjectComponent.this_repo[digital_object_component_child.id]).to be_nil
    end
  end


  it "doesn't give you any schtick if you request a suppressed accession as a manager" do
    accession = create_accession
    accession.set_suppressed(true)

    expect(Accession.this_repo[accession.id]).not_to be_nil
  end


  it "(un)suppresses events that link solely to a (un)suppressed accession" do
    test_agent = create_agent_person
    test_accession = create_accession

    event = create_event(:linked_agents => [{
                                              'ref' => test_agent.uri,
                                              'role' => generate(:agent_role)
                                            }],
                         :linked_records => [{
                                               'ref' => test_accession.uri,
                                               'role' => generate(:record_role)
                                             }])

    create_nobody_user

    as_test_user('nobody') do
      expect(Event.this_repo[event.id]).not_to be_nil
    end

    # Suppressing the accession suppresses the event too
    test_accession.reload
    test_accession.set_suppressed(true)

    as_test_user('nobody') do
      expect(Event.this_repo[event.id]).to be_nil
    end


    # and unsuppressing the accession unsuppresses the event
    test_accession.reload
    test_accession.set_suppressed(false)

    as_test_user('nobody') do
      expect(Event.this_repo[event.id]).not_to be_nil
    end
  end

end
