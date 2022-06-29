require_relative 'spec_helper'

describe 'Related agents' do

  it "Allows agents to be related using directional relationships" do

    earlier_company = create(:json_agent_corporate_entity)

    relationship = JSONModel(:agent_relationship_earlierlater).new
    relationship.relator = 'is_later_form_of'
    relationship.ref = earlier_company.uri

    later_company = create(:json_agent_corporate_entity,
                           'related_agents' => [relationship.to_hash])

    earlier_company = JSONModel(:agent_corporate_entity).find(earlier_company.id)
    later_company = JSONModel(:agent_corporate_entity).find(later_company.id)

    expect(earlier_company.related_agents[0]['relator']).to eq('is_earlier_form_of')
    expect(later_company.related_agents[0]['relator']).to eq('is_later_form_of')
  end

  it 'updates agent relationship specific relators when enumerations are merged' do
    # Add some custom relators
    enum = Enumeration.find(:name => 'agent_relationship_specific_relator')
    enum.add_enumeration_value(:value => 'first', :position => 9001)
    enum.add_enumeration_value(:value => 'second', :position => 9002)

    person1 = create(:json_agent_person)
    relationship = JSONModel(:agent_relationship_associative).new
    relationship.relator = 'is_associative_with'
    relationship.specific_relator = 'first'
    relationship.ref = person1.uri
    person2 = create(:json_agent_person,
                     'related_agents' => [relationship.to_hash])

    expect(person2.related_agents[0]['specific_relator']).to eq('first')

    # Merge the enums
    enum = Enumeration.find(:name => 'agent_relationship_specific_relator')
    obj = JSONModel(:enumeration).find(enum.id)
    request = JSONModel(:enumeration_migration).from_hash(:enum_uri => obj.uri,
                                                          :from => 'first',
                                                          :to => 'second')
    request.save

    person2 = JSONModel(:agent_person).find(person2.id)
    expect(person2.related_agents[0]['specific_relator']).not_to eq('first')
    expect(person2.related_agents[0]['specific_relator']).to eq('second')
  end

  it 'Supports related agents with date records' do
    parent = create(:json_agent_person)
    date = build(:json_structured_date_label).to_hash

    relationship = JSONModel(:agent_relationship_parentchild).new
    relationship.relator = 'is_child_of'
    relationship.ref = parent.uri
    relationship.dates = date

    child = create(:json_agent_person, 'related_agents' => [relationship.to_hash])

    child = JSONModel(:agent_person).find(child.id)
    expect(child.related_agents.first['dates']['structured_date_single']['date_expression']).to eq(date['structured_date_single']['date_expression'])

    # Updates work too
    expect(lambda {
      child.save
    }).not_to raise_error
  end

end
