require 'spec_helper'

describe "Deletion of Archival Records" do

  before(:each) do
    test_data = File.read(File.join(File.dirname(__FILE__), 'sample_record_set.dat'))
    post "/repositories/#{$repo_id}/batch_imports", test_data
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

    linked1 = event1.linked_records(:event_link).first
    linked2 = event2.linked_records(:event_link).first

    # We can delete the events
    event1.delete
    event2.delete

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

    acc.my_relationships(:subject).count.should eq(0)
  end


  it "can delete an agent" do
    acc = Accession.where(:title => "A test accession").first
    acc.my_relationships(:linked_agents).count.should eq(1)

    agent = AgentSoftware[1]
    agent.should_not be(nil)

    agent.delete

    acc.my_relationships(:linked_agents).count.should eq(0)
  end


  xit "can delete a repository" do
    acc = Accession.where(:title => "A test accession").first
    resource = Resource.where(:title => "A test resource").first

    Repository[$repo_id].delete

    Repository[$repo_id].should be(nil)
    Accession.where(:title => "A test accession").first.should be(nil)
    Resource.where(:title => "A test resource").first.should be(nil)
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
    }.to raise_error
  end

end
