require 'spec_helper'

describe 'Merge request controller' do

  it "can merge two subjects" do
    target = create(:json_subject)
    victim = create(:json_subject)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'subject')

    expect {
      JSONModel(:subject).find(victim.id)
    }.to raise_error(RecordNotFound)
  end


  it "doesn't mess things up if you merge something with itself" do
    target = create(:json_subject)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => target.uri}]

    request.save(:record_type => 'subject')

    expect {
      JSONModel(:subject).find(target.id)
    }.to_not raise_error
  end


  it "throws an error if you ask it to merge something other than a subject" do
    target = create(:json_subject)
    victim = create(:json_agent_person)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    expect {
      request.save(:record_type => 'subject')
    }.to raise_error(JSONModel::ValidationException)
  end


  it "can merge two agents" do
    target = create(:json_agent_person)
    victim = create(:json_agent_person)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'agent')

    expect {
      JSONModel(:agent_person).find(victim.id)
    }.to raise_error(RecordNotFound)
  end


  it "can merge two agents of different types" do
    target = create(:json_agent_person)
    victim = create(:json_agent_corporate_entity)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'agent')

    expect {
      JSONModel(:agent_corporate_entity).find(victim.id)
    }.to raise_error(RecordNotFound)
  end


  it "can merge two resources" do
    target = create(:json_resource)
    victim = create(:json_resource)

    victim_ao = create(:json_archival_object,
                       :resource => {'ref' => victim.uri})

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'resource')

    # Victim is gone
    expect {
      JSONModel(:resource).find(victim.id)
    }.to raise_error(RecordNotFound)

    # The children were moved
    merged_tree = JSONModel(:resource_tree).find(nil, :resource_id => target.id)
    merged_tree.children.any? {|child| child['record_uri'] == victim_ao.uri}.should be(true)

    # An event was created
    Event.this_repo.all.any? {|event|
      event.outcome_note.should match(/#{victim.title}/)
    }.should be(true)
  end


  it "can merge two digital objects" do
    target = create(:json_digital_object)
    victim = create(:json_digital_object)

    victim_doc = create(:json_digital_object_component,
                        :digital_object => {'ref' => victim.uri})

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'digital_object')

    # Victim is gone
    expect {
      JSONModel(:digital_object).find(victim.id)
    }.to raise_error(RecordNotFound)

    # The children were moved
    merged_tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => target.id)
    merged_tree.children.any? {|child| child['record_uri'] == victim_doc.uri}.should be(true)

    # An event was created
    Event.this_repo.all.any? {|event|
      event.outcome_note.should match(/#{victim.title}/)
    }.should be(true)
  end




end
