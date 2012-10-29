require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    test_opts = {:names => [
                  {
                    "rules" => "local",
                    "primary_name" => "Magus Magoo Inc",
                    "sort_name" => "Magus Magoo Inc"
                  },
                  {
                    "rules" => "local",
                    "primary_name" => "Magus McGoo PTY LTD",
                    "sort_name" => "McGoo, M"
                  }
                ]}

    agent = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, test_opts))

    AgentCorporateEntity[agent[:id]].name_corporate_entity.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do

    test_opts = {:agent_contacts => [
                         {
                           "name" => "Business hours contact",
                           "telephone" => "0011 1234 1234"
                         }
                        ]
                }

    agent = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, test_opts))

    AgentCorporateEntity[agent[:id]].agent_contact.length.should eq(1)
    AgentCorporateEntity[agent[:id]].agent_contact[0][:name].should eq("Business hours contact")
  end


  it "requires a source to be set if an authority id is provided" do

    test_opts = {:names => [
                        {
                          "authority_id" => "wooo",
                          "primary_name" => "Magus Magoo Inc",
                          "sort_name" => "Magus Magoo Inc"
                        }
                      ]
                }

    expect { 
      agent = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, test_opts))
     }.to raise_error(JSONModel::ValidationException)
  end
end
