require 'spec_helper'

describe 'Implied publication' do

  it "an agent record is published if linked to a published record" do
    agent = create_agent_person
    agent2 = create_agent_person

    5.times do |i|
      create(:json_resource,
             :publish => (i == 2),
             :linked_agents => [{
                                  'ref' => agent.uri,
                                  'role' => 'source'
                                },
                                {
                                  'ref' => agent2.uri,
                                  'role' => 'source'
                                }])
    end

    jsons = AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id], AgentPerson[agent2.id]])

    jsons.all? {|json| json['is_linked_to_published_record']}.should be(true)
  end

  it "a subject record is published if linked to a published record" do
    subject = create(:json_subject)
    subject2 = create(:json_subject)

    5.times do |i|
      create(:json_resource,
             :publish => (i == 2),
             :subjects => [{
                             'ref' => subject.uri,
                           },
                           {
                             'ref' => subject2.uri,
                           }])
    end

    jsons = Subject.sequel_to_jsonmodel([Subject[subject.id], Subject[subject2.id]])

    jsons.all? {|json| json['is_linked_to_published_record']}.should be(true)
  end

end
