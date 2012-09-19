require 'spec_helper'

describe 'Agent Family model' do

  it "allows family agent to be created" do

    agent = AgentFamily.create_from_json(JSONModel(:agent_family)
                                           .from_hash({
                                                        "agent_type" => "agent_family",
                                                        "names" => [
                                                                    {
                                                                      "rules" => "local",
                                                                      "family_name" => "Magoo Family",
                                                                      "sort_name" => "Family Magoo"
                                                                    },
                                                                    {
                                                                      "rules" => "local",
                                                                      "family_name" => "McGoo Family",
                                                                      "sort_name" => "Family McGoo"
                                                                    }
                                                                   ]
                                                      }))

    AgentFamily[agent[:id]].name_family.length.should eq(2)
  end


  it "allows family agents to have a linked contact details" do

    agent = AgentFamily.create_from_json(JSONModel(:agent_family)
                                     .from_hash({
                                                  "agent_type" => "agent_family",
                                                   "names" => [
                                                               {
                                                                 "rules" => "local",
                                                                 "family_name" => "Magoo Family",
                                                                 "sort_name" => "Family Magoo"
                                                               }
                                                               ],
                                                    "agent_contacts" => [
                                                                         {
                                                                           "name" => "Business hours contact",
                                                                           "telephone" => "0011 1234 1234"
                                                                         }
                                                                        ]
                                                }))

    AgentFamily[agent[:id]].agent_contacts.length.should eq(1)
    AgentFamily[agent[:id]].agent_contacts[0][:name].should eq("Business hours contact")
  end


  it "requires a source to be set if an authority id is provided" do
    expect { 
      agent = AgentFamily.create_from_json(JSONModel(:agent_family)
                                     .from_hash({
                                                  "agent_type" => "agent_family",
                                                   "names" => [
                                                               {
                                                                 "authority_id" => "wooo",
                                                                 "family_name" => "Magoo Family",
                                                                 "sort_name" => "Family Magoo"
                                                               }
                                                               ]
                                                }))
     }.to raise_error(JSONModel::ValidationException)
  end
end
