require 'spec_helper'

describe "Deletion of Archival Records" do

  before(:each) do
    test_data = File.read(File.join(File.dirname(__FILE__), 'sample_record_set.dat'))
    test_data = test_data.gsub('/repositories/{{repo_id}}', "/repositories/#{$repo_id}")
    post "/repositories/#{$repo_id}/batch_imports", test_data
    raise "Test data import failed: #{last_response.body}" unless last_response.status == 200
  end


  it "can delete an accession" do
    resource = Resource.where(:title => "A test resource").first
    expect(resource.my_relationships(:spawned)).not_to eq([])

    acc = Accession.where(:title => "A test accession").first
    expect(acc).not_to be_nil
    acc.delete
    expect(Accession.where(:title => "A test accession").first).to be_nil

    # No more relationship either
    expect(resource.my_relationships(:spawned)).to eq([])
  end


  it "can delete an archival object (possibly with children)" do
    ao_with_child = ArchivalObject.where(:title => "test archival object 1").first
    ao_without_child = ArchivalObject.where(:title => "test archival object 2").first

    expect(ao_with_child).not_to be_nil
    expect(ao_without_child).not_to be_nil

    ao_with_child.delete
    ao_without_child.delete

    # All gone!
    expect(ArchivalObject.where(:title => "test archival object 1").first).to be_nil
    expect(ArchivalObject.where(:title => "test archival object 1.5").first).to be_nil
    expect(ArchivalObject.where(:title => "test archival object 2").first).to be_nil
  end


  it "can delete a resource (and all children)" do
    acc = Accession.where(:title => "A test accession").first
    expect(acc.my_relationships(:spawned)).not_to eq([])

    resource = Resource.where(:title => "A test resource").first
    expect(resource).not_to be_nil

    resource.delete

    # The resource is gone
    expect(Resource.where(:title => "A test resource").first).to be_nil

    # And all the Archival Objects underneath it are gone too
    expect(ArchivalObject.where(:title => "test archival object 1").first).to be_nil
    expect(ArchivalObject.where(:title => "test archival object 1.5").first).to be_nil
    expect(ArchivalObject.where(:title => "test archival object 2").first).to be_nil

    # The accession has no related resource any more
    expect(acc.my_relationships(:spawned)).to eq([])
  end


  it "can delete a digital object (and all children)" do
    digital_object = DigitalObject.where(:title => "A test digital object").first
    expect(digital_object).not_to be_nil

    digital_object.delete

    # The digital object is gone
    expect(DigitalObject.where(:title => "A test digital object").first).to be_nil

    # And all the Digital Object Components underneath it are gone too
    expect(DigitalObjectComponent.where(:title => "digital object child 1").first).to be_nil
    expect(DigitalObjectComponent.where(:title => "digital object child 1.5").first).to be_nil
    expect(DigitalObjectComponent.where(:title => "digital object child 2").first).to be_nil
  end


  it "can delete an event" do
    event1 = Event.where(:outcome_note => "test event 1").first
    event2 = Event.where(:outcome_note => "test event 2").first

    linked1 = event1.related_records(:event_link).first
    linked2 = event2.related_records(:event_link).first

    # We can delete the events
    event1.delete
    event2.delete

    expect(Event[event1.id]).to be_nil
    expect(Event[event2.id]).to be_nil

    # With the linked records unharmed!
    expect {
      linked1.refresh
      linked2.refresh
    }.not_to raise_error
  end


  it "can delete a subject" do
    r = Resource.where(:title => "A test resource").first

    expect(r.my_relationships(:subject).count).to eq(1)

    subject = Subject.where(:title => "a -- test -- subject").first
    expect(subject).not_to be_nil

    subject.delete

    expect(Subject[subject.id]).to be_nil

    expect(r.my_relationships(:subject).count).to eq(0)
  end


  it "can delete an agent" do
    agent = AgentSoftware.create_from_json(build(:json_agent_software))

    acc = Accession.create_from_json(build(:json_accession,
                                           :linked_agents => [{
                                                                'ref' => agent.uri,
                                                                'role' => 'creator'
                                                              }]))
    expect(acc.my_relationships(:linked_agents).count).to eq(1)

    agent.delete

    expect(AgentSoftware[agent.id]).to be_nil

    expect(acc.my_relationships(:linked_agents).count).to eq(0)
  end


  it "can delete a group" do
    group = Group.create_from_json(build(:json_group,
                                         :member_usernames => ["admin"]),
                                   :repo_id => $repo_id)

    last_notification = Notifications.last_notification
    expect(Group[group.id]).not_to be_nil
    group.delete
    expect(Group[group.id]).to be_nil
    expect(Notifications.last_notification).not_to eq(last_notification)
  end


  it "can delete a user (and their corresponding agent)" do
    user = create_nobody_user

    expect(AgentPerson[user.agent_record_id]).not_to be_nil

    user.delete

    expect(User[user.id]).to be_nil
    expect(AgentPerson[user.agent_record_id]).to be_nil
  end


  it "cannot delete a user's corresponding agent" do
    user = create_nobody_user
    agent = AgentPerson.to_jsonmodel(user.agent_record_id)

    expect {
      agent.delete
    }.to raise_error(ConflictException, "linked_to_user")
  end


  it "won't delete a system user" do
    expect {
      User[:username => "admin"].delete
    }.to raise_error(AccessDeniedException)
  end


  it "can delete a location" do
    location = Location.create_from_json(build(:json_location))
    expect(location).not_to be_nil

    location.delete

    expect(Location[location.id]).to be_nil
  end


  it "won't delete a location with links to instances" do
    location = Location.create_from_json(build(:json_location))
    top_container = create(:json_top_container,
                           :container_locations => [{'ref' => location.uri,
                                                      'status' => 'current',
                                                      'start_date' => generate(:yyyy_mm_dd),
                                                      'end_date' => generate(:yyyy_mm_dd)}])

    acc = Accession.create_from_json(build(:json_accession,
                                           :instances => [build(:json_instance,
                                               :sub_container => build(:json_sub_container,
                                                                       :top_container => {:ref => top_container.uri}))]
                                           ))

    expect {
      location.delete
    }.to raise_error(ConflictException)
  end

end
