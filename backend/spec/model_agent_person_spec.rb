require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    n1 = build(:json_name_person)
    n2 = build(:json_name_person)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1, n2]))

    expect(AgentPerson[agent[:id]].name_person.length).to eq(2)
  end


  it "doesn't have a leading whitespace in the sort name" do

    n1 = build(:json_name_person, :rest_of_name => nil)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1]))

    expect(AgentPerson[agent[:id]].name_person.first[:sort_name]).to match(Regexp.new("^#{n1.primary_name}.*"))
  end


  it "allows agents to have a linked contact details" do

    c1 = build(:json_agent_contact)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :agent_contacts => [c1]))

    expect(AgentPerson[agent[:id]].agent_contact.length).to eq(1)
    expect(AgentPerson[agent[:id]].agent_contact[0][:name]).to eq(c1.name)
  end


  it "will allow one contact to be flagged 'is_representative'" do
    c1 = build(:json_agent_contact, is_representative: false)
    c2 = build(:json_agent_contact, is_representative: true)
    c3 = build(:json_agent_contact, is_representative: false)

    expect {
      AgentPerson.create_from_json(build(:json_agent_person, :agent_contacts => [c1, c2, c3]))
    }.to_not raise_error(Sequel::ValidationFailed)
  end


  it "won't allow more than one contact to be flagged 'is_representative'" do
    c1 = build(:json_agent_contact, is_representative: false)
    c2 = build(:json_agent_contact, is_representative: true)
    c3 = build(:json_agent_contact, is_representative: true)

    expect {
      AgentPerson.create_from_json(build(:json_agent_person, :agent_contacts => [c1, c2, c3]))
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "for authorized names, requires rules to be set if source is not provided" do
    expect { n1 = build(:json_name_person, :rules => nil, :source => nil, :authorized => true).to_hash }.to raise_error(JSONModel::ValidationException)
  end


  it "for authorized names, require rules to be set if source is not provided (even if the name is only implicitly authorized)" do
    expect {
      name = build(:json_name_person, :rules => nil, :source => nil, :authorized => false)

      AgentPerson.create_from_json(build(:json_agent_person, :names => [name]))
    }.to raise_error(JSONModel::ValidationException)
  end


  it "for unauthorized names, no requirement for source or rules" do
    expect { n1 = build(:json_name_person, :rules => nil, :source => nil, :authorized => false, :authority_id => nil).to_hash }.not_to raise_error
  end


  it "requires a source to be set if an authority id is provided, but only in strict mode" do

    expect { n1 = build(:json_name_person, :authority_id => 'wooo', :source => nil).to_hash }.to raise_error(JSONModel::ValidationException)

    JSONModel.strict_mode(false)

    expect { n1 = build(:json_name_person, :authority_id => 'wooo').to_hash }.not_to raise_error

    JSONModel.strict_mode(true)

  end


  it "allows rules to be nil if authority id and source are provided" do

    n1 = build(:json_name_person,
                {:rules => nil,
                 :source => 'local',
                 :authority_id => '123123'
                }
              )

    expect { n1.to_hash }.not_to raise_error

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1]))

    expect(AgentPerson[agent[:id]].name_person.length).to eq(1)
  end


  it "requires a sort_name if sort_name_auto_generate is false" do
    expect { build(:json_name_person, :sort_name => nil, :sort_name_auto_generate => false).to_hash }.to raise_error(JSONModel::ValidationException)
  end


  it "truncates an auto-generated sort name of more than 255 chars" do
    name = build(:json_name_person,
                 :primary_name => (0..200).map { rand(3)==1?rand(10):(65 + rand(25)).chr }.join,
                 :rest_of_name => (0..200).map { rand(3)==1?rand(10):(65 + rand(25)).chr }.join
                 )

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [name]))
    expect(JSONModel(:agent_person).find(agent[:id]).names[0]['sort_name'].length).to eq(255)
  end


  it "allows dates_of_existence for an agent, and filters out other labels" do
    n = build(:json_name_person)

    d1 = build(:json_structured_date_label, :date_label => 'existence')
    d2 = build(:json_structured_date_label, :date_label => 'creation')

    agent = AgentPerson.create_from_json(build(:json_agent_person, {:names => [n], :dates_of_existence => [d1]}))

    expect(JSONModel(:agent_person).find(agent[:id]).dates_of_existence.length).to eq(1)

    expect { AgentPerson.create_from_json(build(:json_agent_person, {:names => [n], :dates_of_existence => [d2]})) }.to raise_error(JSONModel::ValidationException)
  end


  it "can merge one agent into another" do
    merge_candidate_agent = AgentPerson.create_from_json(build(:json_agent_person))
    merge_destination_agent = AgentPerson.create_from_json(build(:json_agent_person))

    # A record that uses the merge_candidate agent
    acc = create(:json_accession, 'linked_agents' => [{
                                                        'ref' => merge_candidate_agent.uri,
                                                        'role' => 'source'
                                                      }])

    merge_destination_agent.assimilate([merge_candidate_agent])

    expect(JSONModel(:accession).find(acc.id).linked_agents[0]['ref']).to eq(merge_destination_agent.uri)

    expect(merge_candidate_agent.exists?).to be_falsey
  end


  it "handles related agents when merging" do
    merge_candidate_agent = AgentPerson.create_from_json(build(:json_agent_person))
    merge_destination_agent = AgentPerson.create_from_json(build(:json_agent_person))

    relationship = JSONModel(:agent_relationship_parentchild).new
    relationship.relator = "is_child_of"
    relationship.ref = merge_candidate_agent.uri
    related_agent = create(:json_agent_person, "related_agents" => [relationship.to_hash])

    # Merging merge_candidate into merge_destination updates the related agent relationship too
    merge_destination_agent.assimilate([merge_candidate_agent])
    expect(JSONModel(:agent_person).find(related_agent.id).related_agents[0]['ref']).to eq(merge_destination_agent.uri)
  end


  it "can merge different agent types into another" do
    merge_candidate_agent = AgentFamily.create_from_json(build(:json_agent_family))
    merge_destination_agent = AgentPerson.create_from_json(build(:json_agent_person))

    # A record that uses the merge_candidate agent
    acc = create(:json_accession, 'linked_agents' => [{
                                                        'ref' => merge_candidate_agent.uri,
                                                        'role' => 'source'
                                                      }])

    merge_destination_agent.assimilate([merge_candidate_agent])
    expect(JSONModel(:accession).find(acc.id).linked_agents[0]['ref']).to eq(merge_destination_agent.uri)

    expect(merge_candidate_agent.exists?).to be_falsey
  end


  it "can merge different agent types into another, even if they have the same DB id" do
    merge_candidate_agent = AgentFamily.create_from_json(build(:json_agent_family))
    merge_destination_agent = AgentPerson.create_from_json(build(:json_agent_person))

    db_id = [merge_candidate_agent.id, merge_destination_agent.id].max
    (merge_candidate_agent.id - merge_destination_agent.id).abs.times do |n|
      AgentFamily.create_from_json(build(:json_agent_family))
      AgentPerson.create_from_json(build(:json_agent_person))
    end

    merge_candidate_agent = AgentFamily[db_id]
    merge_destination_agent = AgentPerson[db_id]

    merge_destination_agent.assimilate([merge_candidate_agent])
    expect(merge_candidate_agent.exists?).to be_falsey
  end


  it "can get a list of roles that a given agent participates in" do
    person_agent = AgentPerson.create_from_json(build(:json_agent_person))

    acc = create(:json_accession, 'linked_agents' => [{
                                                        'ref' => person_agent.uri,
                                                        'role' => 'source'
                                                      }])


    expect(person_agent.linked_agent_roles).to eq(['source'])
  end


  it "can link an agent without a role to a rights statement" do
    agent = create(:json_agent_person)
    resource = create(:json_resource,
                      'rights_statements' => [build(:json_rights_statement,
                                                    'linked_agents' => [{
                                                        'ref' => agent.uri
                                                      }])
                                              ])

    expect {
      AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id]])
    }.not_to raise_error
  end


  it "can mark an agent's name as authorized" do
    person_agent = AgentPerson.create_from_json(build(:json_agent_person,
                                                      :names => [build(:json_name_person, 'authorized' => false),
                                                                 build(:json_name_person, 'authorized' => true)]))

    agent = AgentPerson.to_jsonmodel(person_agent.id)

    expect(agent.names[0]['authorized']).to be_falsey
    expect(agent.names[1]['authorized']).to be_truthy
  end


  it "ensures that an agent only has one authorized name" do
    expect {
      AgentPerson.create_from_json(build(:json_agent_person,
                                                      :names => [build(:json_name_person,
                                                                       'authorized' => true),
                                                                 build(:json_name_person,
                                                                       'authorized' => true)]))
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "takes the first name as authorized if no indication is present" do
    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [build(:json_name_person,
                                                                'authorized' => false),
                                                          build(:json_name_person,
                                                                'authorized' => false)]))

    expect(AgentPerson.to_jsonmodel(agent.id).names[0]['authorized']).to be_truthy
    expect(AgentPerson.to_jsonmodel(agent.id).names[1]['authorized']).to be_falsey
  end


  it "doesn't allow two agent records to have a name with the same authority ID" do
    expect {
      2.times do
        AgentPerson.create_from_json(build(:json_agent_person,
                                           :names => [build(:json_name_person,
                                                            'authority_id' => 'same',
                                                            'authorized' => true)]))
      end
    }.to raise_error(Sequel::ValidationFailed)
  end

  it "returns the existing agent if an name authority id is already in place " do
    json =    build( :json_agent_person,
                     :names => [build(:json_name_person,
                     'authority_id' => 'thesame'
                     )])
    json2 = build( :json_agent_person,
                     :names => [build(:json_name_person,
                     'authority_id' => 'thesame'
                     )])

    a1 =    AgentPerson.create_from_json(json)
    a2 =    AgentPerson.ensure_exists(json2, nil)

    expect(a1).to eq(a2) # the names should still be the same as the first authority_id names
  end


  it "supports having a display name" do
    display_name = build(:json_name_person,
                         'authorized' => false,
                         'is_display_name' => true)
    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [display_name,
                                                          build(:json_name_person,
                                                                'authorized' => true,
                                                                'is_display_name' => false)]))

    expect(AgentPerson.to_jsonmodel(agent.id).display_name['primary_name']).to eq(display_name['primary_name'])
  end


  it "stops agents from having more than one display name" do
    expect {
      AgentPerson.create_from_json(build(:json_agent_person,
                                         :names => [build(:json_name_person,
                                                          'authorized' => false,
                                                          'is_display_name' => true),
                                                    build(:json_name_person,
                                                          'authorized' => true,
                                                          'is_display_name' => true)]))
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "defaults the display name to the authorized name" do
    authorized_name = build(:json_name_person, 'authorized' => true)

    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [build(:json_name_person, 'authorized' => false),
                                                          authorized_name]))

    expect(AgentPerson.to_jsonmodel(agent.id).display_name['primary_name']).to eq(authorized_name['primary_name'])
  end


  it "combines unauthorized names when they're the same field-for-field" do
    unique_name = build(:json_name_person, 'authorized' => true)

    name_template = build(:json_name_person, 'authorized' => false)
    values = name_template.to_hash.reject {|name, val| val.nil?}

    duplicated_name = JSONModel(:name_person).from_hash(values)
    another_duplicated_name = JSONModel(:name_person).from_hash(values)

    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [unique_name, duplicated_name, another_duplicated_name]))

    expect(AgentPerson.to_jsonmodel(agent.id).names.length).to eq(2)
  end


  it "preserves the display name when combining two unauthorized names" do
    unique_name = build(:json_name_person, 'authorized' => true)

    name_template = build(:json_name_person, 'authorized' => false)
    values = name_template.to_hash.reject {|name, val| val.nil?}

    duplicated_name = JSONModel(:name_person).from_hash(values)

    another_duplicated_name = JSONModel(:name_person).from_hash(values)
    another_duplicated_name.is_display_name = true

    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [unique_name, duplicated_name, another_duplicated_name]))

    expect(AgentPerson.to_jsonmodel(agent.id).names.length).to eq(2)
    expect(AgentPerson.to_jsonmodel(agent.id).names[1]['is_display_name']).to be_truthy
  end

  it "appends the name date to the agent software sort name" do
    json = build(:json_agent_person,
                 :names => [build(:json_name_person,
                    'dates' => '1981'
                )])

    AgentPerson.create_from_json(json)

    name_person = json['names'][0]
    expect(name_person['sort_name']).to match(/1981/)
  end

  it "preserves the display name when combining the authorized name with an unauthorized name" do
    authorized_name = build(:json_name_person, 'authorized' => true)

    values = authorized_name.to_hash.reject {|name, val| val.nil?}
    duplicated_name = JSONModel(:name_person).from_hash(values)
    duplicated_name.authorized = false
    duplicated_name.is_display_name = true

    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [authorized_name, duplicated_name]))

    expect(AgentPerson.to_jsonmodel(agent.id).names.length).to eq(1)
    expect(AgentPerson.to_jsonmodel(agent.id).names[0]['is_display_name']).to be_truthy
  end


  it "can update an agent's name list" do
    name = build(:json_name_person,
                 'authorized' => true,
                 'source' => 'local',
                 'authority_id' => 'something_great')
    agent_obj = AgentPerson.create_from_json(build(:json_agent_person, :names => [name]))

    agent = AgentPerson.to_jsonmodel(agent_obj.id)

    agent.names[0]['primary_name'] = 'something else'

    RequestContext.in_global_repo do
      agent_obj.update_from_json(JSONModel(:agent_person).from_hash(agent.to_hash))
    end
  end


  describe "non-duplicative agents" do

    let(:agent) {
      build(:json_agent_person,
            :names => [build(:json_name_person, :authority_id => nil),
                       build(:json_name_person, :authority_id => nil)],
            :agent_contacts => [build(:json_agent_contact)],
            :external_documents => [build(:json_external_document)],
            :notes => [build(:json_note_bioghist,
                             :subnotes => [ build(:json_note_outline),
                                            build(:json_note_text) ])]
            )
    }

    before(:each) do
      @agent_obj = AgentPerson.create_from_json(agent)
    end

    it "won't create the 'same exact' agent twice" do
      expect { AgentPerson.create_from_json(agent) }.to raise_error(Sequel::ValidationFailed)
    end

    it "will ensure an agent exists if you ask nicely" do
      agent_too = AgentPerson.ensure_exists(agent, nil)
      expect(agent_too.id).to eq(@agent_obj.id)
    end

    it "will accept two agents differing only in one contact field" do
      post_code = agent.agent_contacts[0]['post_code'] || "a"
      agent.agent_contacts[0]['post_code'] = post_code + "x"

      expect { AgentPerson.create_from_json(agent) }.not_to raise_error
    end

    it "will accept two agents differing only in one name field" do
      dates = agent.names[0]['dates'] || "a"
      agent.names[0]['dates'] = dates + "x"

      expect { AgentPerson.create_from_json(agent) }.not_to raise_error
    end

    it "will accept two agents differing only in one external document field" do
      ext_doc_loc = agent.external_documents[0]['location'] || "a"
      agent.external_documents[0]['location'] = ext_doc_loc + "x"

      expect { AgentPerson.create_from_json(agent) }.not_to raise_error
    end

    it "will accept two agents differing only in a note field" do
      agent.notes[0]['subnotes'][0]['levels'][0]['items'][0] << "x"

      expect { AgentPerson.create_from_json(agent) }.not_to raise_error
    end

    it "will *not* consider authority_id when comparing agents" do
      agent.names[0]['authority_id'] = 'x'
      expect { AgentPerson.create_from_json(agent) }.to raise_error(Sequel::ValidationFailed)

      agent.names[0]['primary_name'] += 'x'
      expect { AgentPerson.create_from_json(agent) }.not_to raise_error

      agent.names[0]['authority_id'] = 'y'
      expect { AgentPerson.create_from_json(agent) }.to raise_error(Sequel::ValidationFailed)
    end

    it "will not be fooled by the order of name records" do
      agent.names.unshift(agent.names.pop)

      expect { AgentPerson.create_from_json(agent) }.to raise_error(Sequel::ValidationFailed)
    end

    it "will catch duplications resulting from updates" do
      agent.names[0]['primary_name'] << "x"

      agent_obj = AgentPerson.create_from_json(agent, :is_slug_auto => false)

      agent.names[0]['primary_name'].chomp!('x')

      agent[:lock_version] = 0

      expect {
        RequestContext.in_global_repo do
          agent_obj.update_from_json(JSONModel(:agent_person).from_hash(agent.to_hash))
        end
      }.to raise_error(Sequel::ValidationFailed)

      agent.names[0]['primary_name'] << "y"

      expect {
        RequestContext.in_global_repo do
          agent_obj.update_from_json(JSONModel(:agent_person).from_hash(agent.to_hash))
        end
      }.not_to raise_error
    end

    it "will allow updates to duplicate user-linked agents" do
      users = []
      (0..1).each do |i|
        user = build(:json_user, {:name => 'John Smith',
                                  :username => "jsmith#{i}"})
        users << User.create_from_json(user)
      end

      agent_1 = JSONModel(:agent_person).find(users[0].agent_record_id)
      sha_before = AgentPerson.to_jsonmodel(agent_1.id).agent_sha1
      agent_2 = JSONModel(:agent_person).find(users[1].agent_record_id)

      # No validation error is raised when both are updated
      expect {
        RequestContext.in_global_repo do
          AgentPerson[agent_1.id].update_from_json(AgentPerson.to_jsonmodel(agent_1.id))
          AgentPerson[agent_2.id].update_from_json(AgentPerson.to_jsonmodel(agent_2.id))
        end
      }.not_to raise_error

      # The agent_sha was not changed with the update
      expect(AgentPerson.to_jsonmodel(agent_1.id).agent_sha1).to eq(sha_before)
      # But the record has definitely been updated
      expect(AgentPerson.to_jsonmodel(agent_1.id).lock_version).to eq(1)
    end

    describe "slug tests" do
      before (:all) do
        AppConfig[:use_human_readable_urls] = true
      end

      describe "slug autogen enabled" do
        it "autogenerates a slug via title when configured to generate by name" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_name_person = build(:json_name_person, :name_order => "direct", :rest_of_name => "")
          agent_person = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person])
          )

          expected_slug = clean_slug(get_generated_name_for_agent(agent_person))

          expect(agent_person[:slug]).to match(expected_slug)
        end

        it "autogenerates a slug via identifier when configured to generate by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_person = build(:json_name_person, :authority_id => rand(100000).to_s)
          agent_person = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person])
          )

          expected_slug = clean_slug(agent_name_person[:authority_id])

          expect(agent_person[:slug]).to match(expected_slug)
        end

        it "turns off autogen if slug is blank" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_person = build(:json_name_person, :authority_id => rand(100000).to_s)
          agent_person = AgentPerson.create_from_json(
            build(:json_agent_person,
                  :is_slug_auto => true,
                  :names => [agent_name_person])
          )
          expect(agent_person[:is_slug_auto]).to eq(1)

          agent_person.update(:slug => "")
          expect(agent_person[:is_slug_auto]).to eq(0)
        end

        it "cleans slug when autogenerating by name" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_name_person = build(:json_name_person, :name_order => "direct", :rest_of_name => "")
          agent_person = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person])
          )

          expected_slug = clean_slug(get_generated_name_for_agent(agent_person))

          expect(agent_person[:slug]).to match(expected_slug)
        end

        it "dedupes slug when autogenerating by name" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_name_person1 = build(:json_name_person, :name_order => "direct", :rest_of_name => "", :primary_name => "foo")
          agent_person1 = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person1])
          )

          agent_name_person2 = build(:json_name_person, :name_order => "direct", :rest_of_name => "", :primary_name => "foo")
          agent_person2 = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person2])
          )

          expect(agent_person1[:slug]).to match("foo")
          expect(agent_person2[:slug]).to match("foo_1")
        end


        it "cleans slug when autogenerating by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_person = build(:json_name_person, :authority_id => "Foo Bar Baz&&&&")
          agent_person = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person])
          )

          expect(agent_person[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug when autogenerating by id" do
          AppConfig[:auto_generate_slugs_with_id] = true

          agent_name_person1 = build(:json_name_person, :authority_id => "foo")
          agent_person1 = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person1])
          )

          agent_name_person2 = build(:json_name_person, :authority_id => "foo#")
          agent_person2 = AgentPerson.create_from_json(
            build(:json_agent_person,
                :is_slug_auto => true,
                :names => [agent_name_person2])
          )

          expect(agent_person1[:slug]).to eq("foo")
          expect(agent_person2[:slug]).to eq("foo_1")
        end
      end

      describe "slug autogen disabled" do
        it "slug does not change when config set to autogen by title and title updated" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_person = AgentPerson.create_from_json(build(:json_agent_person, :is_slug_auto => false, :slug => "foo"))

          agent_person.update(:title => rand(100000000))

          expect(agent_person[:slug]).to eq("foo")
        end

        it "slug does not change when config set to autogen by id and id updated" do
          AppConfig[:auto_generate_slugs_with_id] = false

          agent_person = AgentPerson.create_from_json(build(:json_agent_person, :is_slug_auto => false, :slug => "foo"))

          agent_person_name = NamePerson.find(:agent_person_id => agent_person.id)
          agent_person_name.update(:authority_id => rand(100000000))

          expect(agent_person[:slug]).to eq("foo")
        end
      end

      describe "manual slugs" do
        it "cleans manual slugs" do
          agent_person = AgentPerson.create_from_json(build(:json_agent_person, :is_slug_auto => false))
          agent_person.update(:slug => "Foo Bar Baz ###")
          expect(agent_person[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes manual slugs" do
          agent_person1 = AgentPerson.create_from_json(build(:json_agent_person, :is_slug_auto => false, :slug => "foo"))
          agent_person2 = AgentPerson.create_from_json(build(:json_agent_person, :is_slug_auto => false))

          agent_person2.update(:slug => "foo")

          expect(agent_person1[:slug]).to eq("foo")
          expect(agent_person2[:slug]).to eq("foo_1")
        end
      end
    end
  end

end
