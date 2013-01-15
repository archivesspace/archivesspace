require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do
    
    n1 = build(:json_name_person).to_hash
    n2 = build(:json_name_person).to_hash

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1, n2]))

    AgentPerson[agent[:id]].name_person.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do
    
    c1 = build(:json_agent_contact)
    
    agent = AgentPerson.create_from_json(build(:json_agent_person, :agent_contacts => [c1.to_hash]))

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
    
    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1.to_hash]))

    AgentPerson[agent[:id]].name_person.length.should eq(1)
  end


  it "allows for an nil sort_name but it cannot be empty" do

    expect { build(:json_name_person, :sort_name => 'Foo').to_hash }.not_to raise_error(JSONModel::ValidationException)
    expect { build(:json_name_person, :sort_name => nil).to_hash }.not_to raise_error(JSONModel::ValidationException)
    #expect { build(:json_name_person, :sort_name => '').to_hash }.to raise_error(JSONModel::ValidationException)
  end
end
