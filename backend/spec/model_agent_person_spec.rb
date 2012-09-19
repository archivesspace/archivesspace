require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                           .from_hash({
                                                        "agent_type" => "agent_person",
                                                        "names" => [
                                                                    {
                                                                      "rules" => "local",
                                                                      "primary_name" => "Magus Magoo",
                                                                      "sort_name" => "Magoo, Mr M",
                                                                      "direct_order" => "standard"
                                                                    },
                                                                    {
                                                                      "rules" => "local",
                                                                      "primary_name" => "Magus McGoo",
                                                                      "sort_name" => "McGoo, M",
                                                                      "direct_order" => "standard"
                                                                    }
                                                                   ]
                                                      }))

    AgentPerson[agent[:id]].name_person.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do

    agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                     .from_hash({
                                                  "agent_type" => "agent_person",
                                                   "names" => [
                                                               {
                                                                 "rules" => "local",
                                                                 "primary_name" => "Magus Magoo",
                                                                 "sort_name" => "Magoo, Mr M",
                                                                 "direct_order" => "standard"
                                                               }
                                                               ],
                                                    "agent_contacts" => [
                                                                         {
                                                                           "name" => "Business hours contact",
                                                                           "telephone" => "0011 1234 1234"
                                                                         }
                                                                        ]
                                                }))

    AgentPerson[agent[:id]].agent_contacts.length.should eq(1)
    AgentPerson[agent[:id]].agent_contacts[0][:name].should eq("Business hours contact")
  end


  it "requires a rules to be set if source is not provided" do
    expect { 
      agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                     .from_hash({
                                                  "agent_type" => "agent_person",
                                                   "names" => [
                                                               {
                                                                 "primary_name" => "Magus Magoo",
                                                                 "sort_name" => "Magoo, Mr M",
                                                                 "direct_order" => "standard"
                                                               }
                                                               ]
                                                }))
     }.to raise_error(JSONModel::ValidationException)
  end


  it "requires a source to be set if an authority id is provided" do
    expect { 
      agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                     .from_hash({
                                                  "agent_type" => "agent_person",
                                                   "names" => [
                                                               {
                                                                 "authority_id" => "wooo",
                                                                 "primary_name" => "Magus Magoo",
                                                                 "sort_name" => "Magoo, Mr M",
                                                                 "direct_order" => "standard"
                                                               }
                                                               ]
                                                }))
     }.to raise_error(JSONModel::ValidationException)
  end


  it "allows rules to be nil if authority id and source are provided" do
    agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                   .from_hash({
                                                "agent_type" => "agent_person",
                                                 "names" => [
                                                             {
                                                               "authority_id" => "123123",
                                                               "source" => "local",
                                                               "primary_name" => "Magus Magoo",
                                                               "sort_name" => "Magoo, Mr M",
                                                               "direct_order" => "standard"
                                                             }
                                                             ]
                                              }))
    AgentPerson[agent[:id]].name_person.length.should eq(1)
  end
end
