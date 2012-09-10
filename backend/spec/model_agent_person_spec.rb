require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                           .from_hash({
                                                        "agent_type" => "Person",
                                                        "names" => [
                                                                    {
                                                                      "authority_id" => "something",
                                                                      "primary_name" => "Magus Magoo",
                                                                      "sort_name" => "Magoo, Mr M"
                                                                    },
                                                                    {
                                                                      "authority_id" => "else",
                                                                      "primary_name" => "Magus McGoo",
                                                                      "sort_name" => "McGoo, M"
                                                                    }
                                                                   ]
                                                      }))

    AgentPerson[agent[:id]].names.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do

    agent = AgentPerson.create_from_json(JSONModel(:agent_person)
                                     .from_hash({
                                                  "agent_type" => "Person",
                                                   "names" => [
                                                                 {
                                                                   "authority_id" => "something",
                                                                   "primary_name" => "Magus Magoo",
                                                                   "sort_name" => "Magoo, Mr M"
                                                                 }
                                                               ],
                                                    "contact_details" => [
                                                                    {
                                                                      "name" => "Business hours contact",
                                                                      "telephone" => "0011 1234 1234"
                                                                    }
                                                                  ]
                                                }))

    AgentPerson[agent[:id]].contact_details.length.should eq(1)
    AgentPerson[agent[:id]].contact_details[0][:name].should eq("Business hours contact")
  end

end
