require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do
    
    n1 = build(:json_name_software)
    n2 = build(:json_name_software)

    agent = AgentSoftware.create_from_json(build(:json_agent_software, :names => [n1.to_hash, n2.to_hash]))

    AgentSoftware[agent[:id]].name_software.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do
    
    n1 = build(:json_name_software)
    c1 = build(:json_agent_contact)

    agent = AgentSoftware.create_from_json(build(:json_agent_software, {:names => [n1.to_hash], :agent_contacts => [c1.to_hash]}))

    AgentSoftware[agent[:id]].agent_contact.length.should eq(1)
    AgentSoftware[agent[:id]].agent_contact[0][:name].should eq("Business hours contact")
  end


  it "requires a source to be set if an authority id is provided" do
    
    n1 = build(:json_name_software, :authority_id => 'wooo')
    
    expect { 
      n1.to_hash
     }.to raise_error(JSONModel::ValidationException)
  end
end
