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

    expect(AgentFamily[agent[:id]].name_family.length).to eq(2)
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

    expect(AgentFamily[agent[:id]].agent_contact.length).to eq(1)
    expect(AgentFamily[agent[:id]].agent_contact[0][:name]).to eq("Business hours contact")
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

    expect(a1).to eq(a2) # the names should still be the same as the first authority_id names
  end

  describe "slug tests" do
    it "sets family_name as the slug value when configured to generate by name" do
      AppConfig[:auto_generate_slugs_with_id] = false 

      agent = AgentFamily.create_from_json(build(:json_agent_family))

      agent_name = NameFamily.where(:agent_family_id => agent[:id]).first

      expected_slug = agent_name[:family_name].gsub(" ", "_")
                                              .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")



      agent_rec = AgentFamily.where(:id => agent[:id]).first.update(:is_slug_auto => 1)

      expect(agent_rec[:slug]).to eq(expected_slug)
    end

    it "sets family_name as the slug value when configured to generate by id" do
      AppConfig[:auto_generate_slugs_with_id] = true

      agent = AgentFamily.create_from_json(build(:json_agent_family))

      agent_name = NameFamily.where(:agent_family_id => agent[:id]).first

      expected_slug = agent_name[:family_name].gsub(" ", "_")
                                              .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")



      agent_rec = AgentFamily.where(:id => agent[:id]).first.update(:is_slug_auto => 1)

      expect(agent_rec[:slug]).to eq(expected_slug)
    end
  end
end
