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

end
