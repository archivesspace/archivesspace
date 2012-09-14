require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    agent = AgentSoftware.create_from_json(JSONModel(:agent_software)
                                           .from_hash({
                                                        "agent_type" => "agent_software",
                                                        "names" => [
                                                                    {
                                                                      "authority_id" => "something",
                                                                      "software_name" => "Magus Magoo Freeware",
                                                                      "sort_name" => "Magoo, Mr M"
                                                                    },
                                                                    {
                                                                      "authority_id" => "else",
                                                                      "software_name" => "Magus McGoo Vaporware",
                                                                      "sort_name" => "McGoo"
                                                                    }
                                                                   ]
                                                      }))

    AgentSoftware[agent[:id]].name_software.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do

    agent = AgentSoftware.create_from_json(JSONModel(:agent_software)
                                     .from_hash({
                                                  "agent_type" => "agent_software",
                                                   "names" => [
                                                               {
                                                                 "authority_id" => "something",
                                                                 "software_name" => "Magus Magoo Freeware",
                                                                 "sort_name" => "Magoo, Mr M"
                                                               }
                                                               ],
                                                    "agent_contacts" => [
                                                                         {
                                                                           "name" => "Business hours contact",
                                                                           "telephone" => "0011 1234 1234"
                                                                         }
                                                                        ]
                                                }))

    AgentSoftware[agent[:id]].agent_contacts.length.should eq(1)
    AgentSoftware[agent[:id]].agent_contacts[0][:name].should eq("Business hours contact")
  end

end
