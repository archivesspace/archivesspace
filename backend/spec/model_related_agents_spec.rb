require_relative 'spec_helper'

describe 'Related agents' do

  it "Allows agents to be related using directional relationships" do

    earlier_company = create(:json_agent_corporate_entity)

    relationship = JSONModel(:agent_relationship_earlierlater).new
    relationship.relator = "is_later_form_of"
    relationship.ref = earlier_company.uri

    later_company = create(:json_agent_corporate_entity,
                           "related_agents" => [relationship.to_hash])

    earlier_company = JSONModel(:agent_corporate_entity).find(earlier_company.id)
    later_company = JSONModel(:agent_corporate_entity).find(later_company.id)

    earlier_company.related_agents[0]['relator'].should eq ('is_earlier_form_of')
    later_company.related_agents[0]['relator'].should eq ('is_later_form_of')
  end


  it "Supports related agents with date records" do
    parent = create(:json_agent_person)
    date = build(:json_date).to_hash

    relationship = JSONModel(:agent_relationship_parentchild).new
    relationship.relator = "is_child_of"
    relationship.ref = parent.uri
    relationship.dates = date

    child = create(:json_agent_person, "related_agents" => [relationship.to_hash])

    child = JSONModel(:agent_person).find(child.id)
    child.related_agents.first['dates']['begin'].should eq(date['begin'])

    # Updates work too
    lambda {
      child.save
    }.should_not raise_error
  end

end
