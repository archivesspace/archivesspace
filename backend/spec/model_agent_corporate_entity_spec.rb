require 'spec_helper'
require_relative 'spec_slugs_helper'

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

    expect(AgentCorporateEntity[agent[:id]].name_corporate_entity.length).to eq(2)
  end


  it "allows agents to have a linked contact details" do

    contact_name = 'Business hours contact'

    test_opts = {:agent_contacts => [build(:json_agent_contact, :name => contact_name)]}

    agent = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, test_opts))

    expect(AgentCorporateEntity[agent[:id]].agent_contact.length).to eq(1)
    expect(AgentCorporateEntity[agent[:id]].agent_contact[0][:name]).to eq(contact_name)
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

  it "returns the existing agent if an name authority id is already in place " do
    json =    build( :json_agent_corporate_entity,
                     :names => [build(:json_name_corporate_entity,
                     'authority_id' => 'thesame',
                     'source' => 'naf'
                                     )])
    json2 =    build( :json_agent_corporate_entity,
                     :names => [build(:json_name_corporate_entity,
                     'authority_id' => 'thesame',
                     'source' => 'naf'
                     )])
    a1 = AgentCorporateEntity.create_from_json(json)
    a2 = AgentCorporateEntity.ensure_exists(json2, nil)

    expect(a1).to eq(a2) # the names should still be the same as the first authority_id names
  end


  describe "slug tests" do
    describe "slug autogen enabled" do
      it "autogenerates a slug via title when configured to generate by name" do
        AppConfig[:auto_generate_slugs_with_id] = false
 
        agent_name_corporate_entity = build(:json_name_corporate_entity)
        agent_corporate_entity = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity])
        )

        expected_slug = clean_slug(get_generated_name_for_agent(agent_corporate_entity))
 
        expect(agent_corporate_entity[:slug]).to eq(expected_slug)
      end
 
      it "autogenerates a slug via identifier when configured to generate by id" do
        AppConfig[:auto_generate_slugs_with_id] = true

        agent_name_corporate_entity = build(:json_name_corporate_entity, :authority_id => rand(100000).to_s)
        agent_corporate_entity = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity])
        )
 
        expected_slug = clean_slug(agent_name_corporate_entity[:authority_id]) 

        expect(agent_corporate_entity[:slug]).to eq(expected_slug)
      end

      it "turns off autogen if slug is blank" do
        AppConfig[:auto_generate_slugs_with_id] = true

        agent_corporate_entity = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :is_slug_auto => true))
        agent_corporate_entity.update(:slug => "")
 
        expect(agent_corporate_entity[:is_slug_auto]).to eq(0)
      end

      it "cleans slug when autogenerating by name" do
        AppConfig[:auto_generate_slugs_with_id] = false
 
        agent_name_corporate_entity = build(:json_name_corporate_entity)
        agent_corporate_entity = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity])
        )

        expected_slug = clean_slug(get_generated_name_for_agent(agent_corporate_entity))
 
        expect(agent_corporate_entity[:slug]).to eq(expected_slug)
      end

      it "dedupes slug when autogenerating by name" do
        AppConfig[:auto_generate_slugs_with_id] = false
 
        agent_name_corporate_entity1 = build(:json_name_corporate_entity, :primary_name => "foo", :subordinate_name_1 => "", :subordinate_name_2 => "")
        agent_corporate_entity1 = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity1])
        )

        agent_name_corporate_entity2 = build(:json_name_corporate_entity, :primary_name => "foo", :subordinate_name_1 => "", :subordinate_name_2 => "")
        agent_corporate_entity2 = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity2])
        )

        expect(agent_corporate_entity1[:slug]).to eq("foo")
        expect(agent_corporate_entity2[:slug]).to eq("foo_1")
      end


      it "cleans slug when autogenerating by id" do
        AppConfig[:auto_generate_slugs_with_id] = true

        agent_name_corporate_entity = build(:json_name_corporate_entity, :authority_id => "Foo Bar Baz&&&&")
        agent_corporate_entity = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity])
        )
 
        expect(agent_corporate_entity[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes slug when autogenerating by id" do
        AppConfig[:auto_generate_slugs_with_id] = true

        agent_name_corporate_entity1 = build(:json_name_corporate_entity, :authority_id => "foo")
        agent_corporate_entity1 = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity1])
        )

        agent_name_corporate_entity2 = build(:json_name_corporate_entity, :authority_id => "foo#")
        agent_corporate_entity2 = AgentCorporateEntity.create_from_json(
          build(:json_agent_corporate_entity, 
              :is_slug_auto => true, 
              :names => [agent_name_corporate_entity2])
        )
 
        expect(agent_corporate_entity1[:slug]).to eq("foo")
        expect(agent_corporate_entity2[:slug]).to eq("foo_1")
      end
    end
 
    describe "slug autogen disabled" do
      it "slug does not change when config set to autogen by title and title updated" do
        AppConfig[:auto_generate_slugs_with_id] = false
 
        agent_corporate_entity = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :is_slug_auto => false, :slug => "foo"))
 
        agent_corporate_entity.update(:title => rand(100000000))
 
        expect(agent_corporate_entity[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        AppConfig[:auto_generate_slugs_with_id] = false
 
        agent_corporate_entity = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :is_slug_auto => false, :slug => "foo"))
 
        agent_corporate_entity_name = NameCorporateEntity.find(:agent_corporate_entity_id => agent_corporate_entity.id)
        agent_corporate_entity_name.update(:authority_id => rand(100000000))
 
        expect(agent_corporate_entity[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        agent_corporate_entity = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :is_slug_auto => false))
        agent_corporate_entity.update(:slug => "Foo Bar Baz ###")
 
        expect(agent_corporate_entity[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        agent_corporate_entity1 = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :is_slug_auto => false, :slug => "foo"))
        agent_corporate_entity2 = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :is_slug_auto => false))

        agent_corporate_entity2.update(:slug => "foo")

        expect(agent_corporate_entity1[:slug]).to eq("foo")
        expect(agent_corporate_entity2[:slug]).to eq("foo_1")
      end
    end
  end  

end
