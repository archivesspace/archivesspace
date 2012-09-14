require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    agent = AgentCorporateEntity.create_from_json(JSONModel(:agent_corporate_entity)
                                           .from_hash({
                                                        "agent_type" => "agent_corporate_entity",
                                                        "names" => [
                                                                    {
                                                                      "authority_id" => "something",
                                                                      "primary_name" => "Magus Magoo Inc",
                                                                      "sort_name" => "Magus Magoo Inc"
                                                                    },
                                                                    {
                                                                      "authority_id" => "else",
                                                                      "primary_name" => "Magus McGoo PTY LTD",
                                                                      "sort_name" => "McGoo, M"
                                                                    }
                                                                   ]
                                                      }))

    AgentCorporateEntity[agent[:id]].name_corporate_entity.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do

    agent = AgentCorporateEntity.create_from_json(JSONModel(:agent_corporate_entity)
                                     .from_hash({
                                                  "agent_type" => "agent_corporate_entity",
                                                   "names" => [
                                                               {
                                                                 "authority_id" => "something",
                                                                 "primary_name" => "Magus Magoo Inc",
                                                                 "sort_name" => "Magus Magoo Inc"
                                                               }
                                                               ],
                                                    "agent_contacts" => [
                                                                         {
                                                                           "name" => "Business hours contact",
                                                                           "telephone" => "0011 1234 1234"
                                                                         }
                                                                        ]
                                                }))

    AgentCorporateEntity[agent[:id]].agent_contacts.length.should eq(1)
    AgentCorporateEntity[agent[:id]].agent_contacts[0][:name].should eq("Business hours contact")
  end

end
