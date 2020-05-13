require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Agent model' do

  it "allows software agent records to be created with multiple names" do

    n1 = build(:json_name_software)
    n2 = build(:json_name_software)

    agent = AgentSoftware.create_from_json(build(:json_agent_software, :names => [n1, n2]))

    expect(AgentSoftware[agent[:id]].name_software.length).to eq(2)
  end

  it "doesn't allow a software agent record to be created without a name" do
    AppConfig[:use_human_readable_urls] = false
    expect {
      AgentSoftware.create_from_json(build(:json_agent_software, :names => []))
      }.to raise_error(JSONModel::ValidationException)
  end


  it "allows a software agent record to be created with linked contact details" do

    opts = {:name => 'Business hours contact'}

    c1 = build(:json_agent_contact, opts)

    agent = AgentSoftware.create_from_json(build(:json_agent_software, {:agent_contacts => [c1]}))

    expect(AgentSoftware[agent[:id]].agent_contact.length).to eq(1)
    expect(AgentSoftware[agent[:id]].agent_contact[0][:name]).to eq(opts[:name])
  end


  it "requires a source to be set if an authority id is provided" do

    test_opts = {:names => [
                   {
                     "authority_id" => "itsame",
                     "software_name" => "Mario Teaches Typing",
                     "sort_name" => "Mario Teaches Typing"
                   }
                 ]
                }

    expect {
      AgentSoftware.create_from_json(build(:json_agent_software, test_opts))
     }.to raise_error(JSONModel::ValidationException)
  end

  it "returns the existing agent if an name authority id is already in place " do
    json =    build( :json_agent_software,
                     :names => [build(:json_name_software,
                     'authority_id' => 'thesame',
                      'source' => "naf"

                     )])
    json2 =    build( :json_agent_software,
                     :names => [build(:json_name_software,
                     'authority_id' => 'thesame',
                      'source' => "naf"
                     )])

    a1 =    AgentSoftware.create_from_json(json)
    a2 =    AgentSoftware.ensure_exists(json2, nil)

    expect(a1).to eq(a2) # the names should still be the same as the first authority_id names
  end

  it "maintains a record that represents the ArchivesSpace application itself" do
    as_json = AgentSoftware.to_jsonmodel(AgentSoftware.archivesspace_record)
    expect(as_json['names'][0]['version']).to eq ASConstants.VERSION
  end


    describe "slug tests" do
      before (:all) do
        AppConfig[:use_human_readable_urls] = true
      end

      describe "slug autogen enabled" do
        it "autogenerates a slug via title when configured to generate by name" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_name_software = build(:json_name_software)
          agent_software = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software])
          )

          expected_slug = clean_slug(get_generated_name_for_agent(agent_software))

          expect(agent_software[:slug]).to eq(expected_slug)
        end

        it "autogenerates a slug via identifier when configured to generate by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_software = build(:json_name_software, :authority_id => rand(100000).to_s)
          agent_software = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software])
          )

          expected_slug = clean_slug(agent_name_software[:authority_id])

          expect(agent_software[:slug]).to eq(expected_slug)

        end

        it "turns off autogen if slug is blank" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_software = AgentSoftware.create_from_json(build(:json_agent_software, :is_slug_auto => true))
          agent_software.update(:slug => "")
          expect(agent_software[:is_slug_auto]).to eq(0)
        end

        it "cleans slug when autogenerating by name" do
          AppConfig[:auto_generate_slugs_with_id] = false
          agent_name_software = build(:json_name_software)
          agent_software = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software])
          )

          expected_slug = clean_slug(get_generated_name_for_agent(agent_software))
          expect(agent_software[:slug]).to eq(expected_slug)
        end

        it "dedupes slug when autogenerating by name" do
          AppConfig[:auto_generate_slugs_with_id] = false
          agent_name_software1 = build(:json_name_software, :software_name => "foo")
          agent_software1 = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software1])
          )

          agent_name_software2 = build(:json_name_software, :software_name => "foo")
          agent_software2 = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software2])
          )

          expect(agent_software1[:slug]).to eq("foo")
          expect(agent_software2[:slug]).to eq("foo_1")
        end


        it "cleans slug when autogenerating by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_software = build(:json_name_software, :authority_id => "Foo Bar Baz&&&&")
          agent_software = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software])
          )

          expect(agent_software[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug when autogenerating by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_software1 = build(:json_name_software, :authority_id => "foo")

          agent_software1 = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software1])
          )

          agent_name_software2 = build(:json_name_software, :authority_id => "foo#", :software_name => "foo" + rand(100000).to_s)
          agent_software2 = AgentSoftware.create_from_json(
            build(:json_agent_software,
                :is_slug_auto => true,
                :names => [agent_name_software2])
          )
          expect(agent_software1[:slug]).to eq("foo")
          expect(agent_software2[:slug]).to eq("foo_1")
        end
      end

      describe "slug autogen disabled" do
        it "slug does not change when config set to autogen by title and title updated" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_software = AgentSoftware.create_from_json(build(:json_agent_software, :is_slug_auto => false, :slug => "foo"))

          agent_software_name = NameSoftware.find(:agent_software_id => agent_software.id)

          agent_software.update(:name_software => rand(100000000))

          expect(agent_software[:slug]).to eq("foo")
        end

        it "slug does not change when config set to autogen by id and id updated" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_software = AgentSoftware.create_from_json(build(:json_agent_software, :is_slug_auto => false, :slug => "foo"))

          agent_software_name = NameSoftware.find(:agent_software_id => agent_software.id)
          agent_software_name.update(:authority_id => rand(100000000))

          expect(agent_software[:slug]).to eq("foo")
        end
      end

      describe "manual slugs" do
        it "cleans manual slugs" do
          agent_software = AgentSoftware.create_from_json(build(:json_agent_software, :is_slug_auto => false))
          agent_software.update(:slug => "Foo Bar Baz ###")
          expect(agent_software[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes manual slugs" do
          agent_software1 = AgentSoftware.create_from_json(build(:json_agent_software, :is_slug_auto => false, :slug => "foo"))
          agent_software2 = AgentSoftware.create_from_json(build(:json_agent_software, :is_slug_auto => false))

          agent_software2.update(:slug => "foo")

          expect(agent_software1[:slug]).to eq("foo")
          expect(agent_software2[:slug]).to eq("foo_1")
        end
      end
    end

end
