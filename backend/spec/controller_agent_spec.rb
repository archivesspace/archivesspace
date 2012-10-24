require 'spec_helper'

describe 'Generic agent controller' do

  def create_agents
    JSONModel(:agent_person).from_hash(:names => [{
                                                    :rules => "local",
                                                    :primary_name => 'Magus Magoo',
                                                    :direct_order => "standard",
                                                    :sort_name => "1 - MAGOO",
                                                  }],
                                       :agent_contacts => [{
                                                             "name" => "Business hours contact",
                                                             "telephone" => "0011 1234 1234"
                                                           }]
                                       ).save

    JSONModel(:agent_family).from_hash(:names => [{
                                                    "rules" => "local",
                                                    "family_name" => "Magoo Family",
                                                    "sort_name" => "Family Magoo",
                                                  }],
                                       :agent_contacts => [{
                                                             "name" => "Business hours contact",
                                                             "telephone" => "0011 1234 1234"
                                                           }]
                                       ).save

  end


  it "lets you list all agents of any type" do
    create_agents

    types = JSONModel.all('/agents', :agent_type).map {|agent| agent.agent_type}.sort

    types.should eq(["agent_family", "agent_person"])
  end

end
