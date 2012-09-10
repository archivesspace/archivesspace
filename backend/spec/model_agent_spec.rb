require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    agent = Agent.create_from_json(JSONModel(:agent)
                                     .from_hash({
                                                  "agent_type" => JSONModel(:agent_type).uri_for(1),
                                                   "name_forms" => [
                                                                    {"kind" => "Person",
                                                                      "sort_name" => "Magoo, Mr M",
                                                                      "primary_name" => "Magus Magoo"},
                                                                    {"kind" => "Person",
                                                                      "primary_name" => "Magus McGoo",
                                                                      "sort_name" => "McGoo, M"}
                                                                   ]
                                                }))

    Agent[agent[:id]].agent_type_id.should eq(1)
    Agent[agent[:id]].name_forms.length.should eq(2)

    agent = Agent[agent[:id]]
    puts
    puts AgentType[1].inspect
    puts
    puts agent.inspect
    puts
    puts agent.name_forms[0].inspect
    puts agent.name_forms[1].inspect
    puts
    puts NameForm.each { |nf| puts nf.primary_name }
    puts

  end

end
