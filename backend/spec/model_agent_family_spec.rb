require 'spec_helper'
require_relative 'spec_slugs_helper'

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
                     "source" => nil,
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

  it "appends the use date to the end of a agent family display name" do
    name_family = build(:json_name_family)

    name_date = name_family['use_dates'][0]['structured_date_single']['date_expression']

    expect(name_family['sort_name'] =~ /#{name_date}/)
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
      before (:all) do
        AppConfig[:use_human_readable_urls] = true
      end

      describe "slug autogen enabled" do
        it "autogenerates a slug via title when configured to generate by name" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_name_family = build(:json_name_family)
          agent_family = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family])
          )

          expected_slug = clean_slug(get_generated_name_for_agent(agent_family))

          expect(agent_family[:slug]).to match(expected_slug)
        end

        it "autogenerates a slug via identifier when configured to generate by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_family = build(:json_name_family, :authority_id => rand(100000).to_s)
          agent_family = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family])
          )

          expected_slug = clean_slug(agent_name_family[:authority_id])

          expect(agent_family[:slug]).to match(expected_slug)
        end

        it "turns off autogen if slug is blank" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_family = AgentFamily.create_from_json(build(:json_agent_family, :is_slug_auto => true))
          agent_family.update(:slug => "")
          expect(agent_family[:is_slug_auto]).to eq(0)
        end

        it "cleans slug when autogenerating by name" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_name_family = build(:json_name_family)
          agent_family = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family])
          )

          expected_slug = clean_slug(get_generated_name_for_agent(agent_family))
          expect(agent_family[:slug]).to match(expected_slug)
        end

        it "dedupes slug when autogenerating by name" do
          AppConfig[:auto_generate_slugs_with_id] = false
          agent_name_family1 = build(:json_name_family, :family_name => "foo")
          agent_family1 = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family1])
          )

          agent_name_family2 = build(:json_name_family, :family_name => "foo")
          agent_family2 = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family2])
          )

          expect(agent_family1[:slug]).to match("foo")
          expect(agent_family2[:slug]).to match("foo_2")
        end


        it "cleans slug when autogenerating by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_family = build(:json_name_family, :authority_id => "Foo Bar Baz&&&&")
          agent_family = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family])
          )

          expect(agent_family[:slug]).to match("foo_bar_baz")
        end

        it "dedupes slug when autogenerating by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_family1 = build(:json_name_family, :authority_id => "foo")
          agent_family1 = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family1])
          )

          agent_name_family2 = build(:json_name_family, :authority_id => "foo#")
          agent_family2 = AgentFamily.create_from_json(
            build(:json_agent_family,
                :is_slug_auto => true,
                :names => [agent_name_family2])
          )

          expect(agent_family1[:slug]).to match("foo")
          expect(agent_family2[:slug]).to match("foo_1")
        end
      end

      describe "slug autogen disabled" do
        it "slug does not change when config set to autogen by title and title updated" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_family = AgentFamily.create_from_json(build(:json_agent_family, :is_slug_auto => false, :slug => "foo"))

          agent_family.update(:title => rand(100000000))

          expect(agent_family[:slug]).to eq("foo")
        end

        it "slug does not change when config set to autogen by id and id updated" do
          AppConfig[:auto_generate_slugs_with_id] = false
          agent_family = AgentFamily.create_from_json(build(:json_agent_family, :is_slug_auto => false, :slug => "foo"))

          agent_family_name = NameFamily.find(:agent_family_id => agent_family.id)
          agent_family_name.update(:authority_id => rand(100000000))

          expect(agent_family[:slug]).to eq("foo")
        end
      end

      describe "manual slugs" do
        it "cleans manual slugs" do
          agent_family = AgentFamily.create_from_json(build(:json_agent_family, :is_slug_auto => false))
          agent_family.update(:slug => "Foo Bar Baz ###")
          expect(agent_family[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes manual slugs" do
          agent_family1 = AgentFamily.create_from_json(build(:json_agent_family, :is_slug_auto => false, :slug => "foo"))
          agent_family2 = AgentFamily.create_from_json(build(:json_agent_family, :is_slug_auto => false))

          agent_family2.update(:slug => "foo")

          expect(agent_family1[:slug]).to eq("foo")
          expect(agent_family2[:slug]).to eq("foo_1")
        end
      end
    end

end
