require 'spec_helper'

describe 'Agent Family model' do

  it "allows family agent to be created" do
    
    test_opts = {:names => [
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
               }

    agent = AgentFamily.create_from_json(build(:json_agent_family, test_opts))

    AgentFamily[agent[:id]].name_family.length.should eq(2)
  end


  it "allows family agents to have a linked contact details" do
    
    test_opts = {:agent_contacts => [
                   {
                     "name" => "Business hours contact",
                     "telephone" => "0011 1234 1234"
                   }
                  ]
                }
                
    agent = AgentFamily.create_from_json(build(:json_agent_family, test_opts))

    AgentFamily[agent[:id]].agent_contact.length.should eq(1)
    AgentFamily[agent[:id]].agent_contact[0][:name].should eq("Business hours contact")
  end


  it "requires a source to be set if an authority id is provided" do
    
    test_opts = {:names => [
                   {
                     "authority_id" => "wooo",
                     "family_name" => "Magoo Family",
                     "sort_name" => "Family Magoo"
                   }
                 ]
                }
    
    expect { 
      agent = AgentFamily.create_from_json(build(:json_agent_family, test_opts))
     }.to raise_error(JSONModel::ValidationException)
  end

  it "returns the existing agent if an name authority id is already in place " do
    json =    build( :json_agent_family,
                     :names => [build(:json_name_family,
                     'authority_id' => 'thesame',
                     'source' => 'naf'
                     )])
    json2 =    build( :json_agent_family,
                     :names => [build(:json_name_family,
                     'authority_id' => 'thesame',
                     'source' => 'naf'
                     )])
   
    a1 =    AgentFamily.create_from_json(json)
    a2 =    AgentFamily.ensure_exists(json2, nil)
    
    a1.should eq(a2) # the names should still be the same as the first authority_id names 
  end



end
