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
    resource.my_relationships(:spawned).should_not eq([])

    acc = Accession.where(:title => "A test accession").first
    acc.should_not be(nil)
    acc.delete
    Accession.where(:title => "A test accession").first.should be(nil)

    # No more relationship either
    resource.my_relationships(:spawned).should eq([])
  end


  it "can delete an archival object (possibly with children)" do
    ao_with_child = ArchivalObject.where(:title => "test archival object 1").first
    ao_without_child = ArchivalObject.where(:title => "test archival object 2").first

    ao_with_child.should_not be(nil)
    ao_without_child.should_not be(nil)

    ao_with_child.delete
    ao_without_child.delete

    # All gone!
    ArchivalObject.where(:title => "test archival object 1").first.should be(nil)
    ArchivalObject.where(:title => "test archival object 1.5").first.should be(nil)
    ArchivalObject.where(:title => "test archival object 2").first.should be(nil)
  end


  it "can delete a resource (and all children)" do
    acc = Accession.where(:title => "A test accession").first
    acc.my_relationships(:spawned).should_not eq([])

    resource = Resource.where(:title => "A test resource").first
    resource.should_not be(nil)

    resource.delete

    # The resource is gone
    Resource.where(:title => "A test resource").first.should be(nil)

    # And all the Archival Objects underneath it are gone too
    ArchivalObject.where(:title => "test archival object 1").first.should be(nil)
    ArchivalObject.where(:title => "test archival object 1.5").first.should be(nil)
    ArchivalObject.where(:title => "test archival object 2").first.should be(nil)

    # The accession has no related resource any more
    acc.my_relationships(:spawned).should eq([])
  end


  it "can delete a digital object (and all children)" do
    digital_object = DigitalObject.where(:title => "A test digital object").first
    digital_object.should_not be(nil)

    digital_object.delete

    # The digital object is gone
    DigitalObject.where(:title => "A test digital object").first.should be(nil)

    # And all the Digital Object Components underneath it are gone too
    DigitalObjectComponent.where(:title => "digital object child 1").first.should be(nil)
    DigitalObjectComponent.where(:title => "digital object child 1.5").first.should be(nil)
    DigitalObjectComponent.where(:title => "digital object child 2").first.should be(nil)
  end


  it "can delete an event" do
    event1 = Event.where(:outcome_note => "test event 1").first
    event2 = Event.where(:outcome_note => "test event 2").first

    linked1 = event1.related_records(:event_link).first
    linked2 = event2.related_records(:event_link).first

    # We can delete the events
    event1.delete
    event2.delete

    Event[event1.id].should be_nil
    Event[event2.id].should be_nil

    # With the linked records unharmed!
    expect {
      linked1.refresh
      linked2.refresh
    }.to_not raise_error
  end


  it "can delete a subject" do
    acc = Accession.where(:title => "A test accession").first
    acc.my_relationships(:subject).count.should eq(1)

    subject = Subject.where(:title => "a -- test -- subject").first
    subject.should_not be(nil)

    subject.delete

    Subject[subject.id].should be_nil

    acc.my_relationships(:subject).count.should eq(0)
  end


  it "can delete an agent" do
    agent = AgentSoftware.create_from_json(build(:json_agent_software))

    acc = Accession.create_from_json(build(:json_accession,
                                           :linked_agents => [{
                                                                'ref' => agent.uri,
                                                                'role' => 'creator'
                                                              }]))
    acc.my_relationships(:linked_agents).count.should eq(1)

    agent.delete

    AgentSoftware[agent.id].should be_nil

    acc.my_relationships(:linked_agents).count.should eq(0)
  end


  it "can delete a group" do
    group = Group.create_from_json(build(:json_group,
                                         :member_usernames => ["admin"]),
                                   :repo_id => $repo_id)

    last_notification = Notifications.last_notification
    Group[group.id].should_not be(nil)
    group.delete
    Group[group.id].should be(nil)
    Notifications.last_notification.should_not eq(last_notification)
  end


  it "can delete a user (and their corresponding agent)" do
    user = create_nobody_user

    AgentPerson[user.agent_record_id].should_not be(nil)

    user.delete

    User[user.id].should be(nil)
    AgentPerson[user.agent_record_id].should be(nil)
  end


  it "won't delete a system user" do
    expect {
      User[:username => "admin"].delete
    }.to raise_error(AccessDeniedException)
  end


  it "can delete a location" do
    location = Location.create_from_json(build(:json_location))
    location.should_not be(nil)

    location.delete

    Location[location.id].should be_nil
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
