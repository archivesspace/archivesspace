require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do
    
    n1 = build(:json_name_person)
    n2 = build(:json_name_person)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1, n2]))

    AgentPerson[agent[:id]].name_person.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do
    
    c1 = build(:json_agent_contact)
    
    agent = AgentPerson.create_from_json(build(:json_agent_person, :agent_contacts => [c1]))

    AgentPerson[agent[:id]].agent_contact.length.should eq(1)
    AgentPerson[agent[:id]].agent_contact[0][:name].should eq(c1.name)
  end


  it "requires a rules to be set if source is not provided" do
    
    expect { n1 = build(:json_name_person, :rules => nil).to_hash }.to raise_error(JSONModel::ValidationException)
    
  end


  it "requires a source to be set if an authority id is provided" do
    
    expect { n1 = build(:json_name_person, :authority_id => 'wooo').to_hash }.to raise_error(JSONModel::ValidationException)
    
  end


  it "allows rules to be nil if authority id and source are provided" do
    
    n1 = build(:json_name_person, 
                {:rules => nil,
                 :source => 'local',
                 :authority_id => '123123'
                }
              )
    
    expect { n1.to_hash }.to_not raise_error(JSONModel::ValidationException)
    
    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1]))

    AgentPerson[agent[:id]].name_person.length.should eq(1)
  end


  it "requires a sort_name if sort_name_auto_generate is false" do
    expect { build(:json_name_person, :sort_name => nil, :sort_name_auto_generate => false).to_hash }.to raise_error(JSONModel::ValidationException)
  end


  it "allows dates_of_existence for an agent, and filters out other labels" do
    n = build(:json_name_person)

    d1 = build(:json_date, :label => 'existence')
    d2 = build(:json_date, :label => 'creation')
    
    agent = AgentPerson.create_from_json(build(:json_agent_person, {:names => [n], :dates_of_existence => [d1]}))

    JSONModel(:agent_person).find(agent[:id]).dates_of_existence.length.should eq(1)

    expect { AgentPerson.create_from_json(build(:json_agent_person, {:names => [n], :dates_of_existence => [d2]})) }.to raise_error(JSONModel::ValidationException)
  end

end
