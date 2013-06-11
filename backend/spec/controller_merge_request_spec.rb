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

end
