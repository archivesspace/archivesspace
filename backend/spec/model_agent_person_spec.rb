require 'spec_helper'

describe 'Agent model' do

  it "allows agents to be created" do

    n1 = build(:json_name_person)
    n2 = build(:json_name_person)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1, n2]))

    AgentPerson[agent[:id]].name_person.length.should eq(2)
  end


  it "allows agents to have a linked contact details" do

    c1 = build(:json_agent_contact)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :agent_contacts => [c1]))

    AgentPerson[agent[:id]].agent_contact.length.should eq(1)
    AgentPerson[agent[:id]].agent_contact[0][:name].should eq(c1.name)
  end


  it "for authorized names, requires a rules to be set if source is not provided" do
    expect { n1 = build(:json_name_person, :rules => nil, :source => nil, :authorized => true).to_hash }.to raise_error(JSONModel::ValidationException)
  end


  it "for unauthorized names, no requirement for source or rules" do
    expect { n1 = build(:json_name_person, :rules => nil, :source => nil, :authorized => false).to_hash }.to_not raise_error
  end


  it "requires a source to be set if an authority id is provided, but only in strict mode" do

    expect { n1 = build(:json_name_person, :authority_id => 'wooo', :source => nil).to_hash }.to raise_error(JSONModel::ValidationException)

    JSONModel::strict_mode(false)

    expect { n1 = build(:json_name_person, :authority_id => 'wooo').to_hash }.to_not raise_error

    JSONModel::strict_mode(true)

  end


  it "allows rules to be nil if authority id and source are provided" do

    n1 = build(:json_name_person,
                {:rules => nil,
                 :source => 'local',
                 :authority_id => '123123'
                }
              )

    expect { n1.to_hash }.to_not raise_error(JSONModel::ValidationException)

    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [n1]))

    AgentPerson[agent[:id]].name_person.length.should eq(1)
  end


  it "requires a sort_name if sort_name_auto_generate is false" do
    expect { build(:json_name_person, :sort_name => nil, :sort_name_auto_generate => false).to_hash }.to raise_error(JSONModel::ValidationException)
  end


  it "truncates an auto-generated sort name of more than 255 chars" do
    name = build(:json_name_person,
                 :primary_name => (0..200).map{ rand(3)==1?rand(10):(65 + rand(25)).chr }.join,
                 :rest_of_name => (0..200).map{ rand(3)==1?rand(10):(65 + rand(25)).chr }.join 
                 )
    
    agent = AgentPerson.create_from_json(build(:json_agent_person, :names => [name]))
    JSONModel(:agent_person).find(agent[:id]).names[0]['sort_name'].length.should eq(255)
  end


  it "allows dates_of_existence for an agent, and filters out other labels" do
    n = build(:json_name_person)

    d1 = build(:json_date, :label => 'existence')
    d2 = build(:json_date, :label => 'creation')

    agent = AgentPerson.create_from_json(build(:json_agent_person, {:names => [n], :dates_of_existence => [d1]}))

    JSONModel(:agent_person).find(agent[:id]).dates_of_existence.length.should eq(1)

    expect { AgentPerson.create_from_json(build(:json_agent_person, {:names => [n], :dates_of_existence => [d2]})) }.to raise_error(JSONModel::ValidationException)
  end


  it "can merge one agent into another" do
    victim_agent = AgentPerson.create_from_json(build(:json_agent_person))
    target_agent = AgentPerson.create_from_json(build(:json_agent_person))

    # A record that uses the victim agent
    acc = create(:json_accession, 'linked_agents' => [{
                                                        'ref' => victim_agent.uri,
                                                        'role' => 'source'
                                                      }])

    target_agent.assimilate([victim_agent])

    JSONModel(:accession).find(acc.id).linked_agents[0]['ref'].should eq(target_agent.uri)

    victim_agent.exists?.should be(false)
  end


  it "handles related agents when merging" do
    victim_agent = AgentPerson.create_from_json(build(:json_agent_person))
    target_agent = AgentPerson.create_from_json(build(:json_agent_person))

    relationship = JSONModel(:agent_relationship_parentchild).new
    relationship.relator = "is_child_of"
    relationship.ref = victim_agent.uri
    related_agent = create(:json_agent_person, "related_agents" => [relationship.to_hash])

    # Merging victim into target updates the related agent relationship too
    target_agent.assimilate([victim_agent])
    JSONModel(:agent_person).find(related_agent.id).related_agents[0]['ref'].should eq(target_agent.uri)
  end


  it "can merge different agent types into another" do
    victim_agent = AgentFamily.create_from_json(build(:json_agent_family))
    target_agent = AgentPerson.create_from_json(build(:json_agent_person))

    # A record that uses the victim agent
    acc = create(:json_accession, 'linked_agents' => [{
                                                        'ref' => victim_agent.uri,
                                                        'role' => 'source'
                                                      }])

    target_agent.assimilate([victim_agent])
    JSONModel(:accession).find(acc.id).linked_agents[0]['ref'].should eq(target_agent.uri)

    victim_agent.exists?.should be(false)
  end


  it "can merge different agent types into another, even if they have the same DB id" do
    victim_agent = AgentFamily.create_from_json(build(:json_agent_family))
    target_agent = AgentPerson.create_from_json(build(:json_agent_person))

    db_id = [victim_agent.id, target_agent.id].max
    (victim_agent.id - target_agent.id).abs.times do |n|
      AgentFamily.create_from_json(build(:json_agent_family))
      AgentPerson.create_from_json(build(:json_agent_person))
    end

    victim_agent = AgentFamily[db_id]
    target_agent = AgentPerson[db_id]

    target_agent.assimilate([victim_agent])
    victim_agent.exists?.should be(false)
  end


  it "can get a list of roles that a given agent participates in" do
    person_agent = AgentPerson.create_from_json(build(:json_agent_person))

    acc = create(:json_accession, 'linked_agents' => [{
                                                        'ref' => person_agent.uri,
                                                        'role' => 'source'
                                                      }])


    person_agent.linked_agent_roles.should eq(['source'])
  end


  it "can mark an agent's name as authorized" do
    person_agent = AgentPerson.create_from_json(build(:json_agent_person,
                                                      :names => [build(:json_name_person, 'authorized' => false),
                                                                 build(:json_name_person, 'authorized' => true)]))

    agent = AgentPerson.to_jsonmodel(person_agent.id)

    agent.names[0]['authorized'].should be(false)
    agent.names[1]['authorized'].should be(true)
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

    AgentPerson.to_jsonmodel(agent.id).names[0]['authorized'].should be(true)
    AgentPerson.to_jsonmodel(agent.id).names[1]['authorized'].should be(false)
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


  it "supports having a display name" do
    display_name = build(:json_name_person,
                         'authorized' => false,
                         'is_display_name' => true)
    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [display_name,
                                                          build(:json_name_person,
                                                                'authorized' => true,
                                                                'is_display_name' => false)]))
    
    AgentPerson.to_jsonmodel(agent.id).display_name['primary_name'].should eq(display_name['primary_name'])
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

    AgentPerson.to_jsonmodel(agent.id).display_name['primary_name'].should eq(authorized_name['primary_name'])
  end


  it "combines unauthorized names when they're the same field-for-field" do
    unique_name = build(:json_name_person, 'authorized' => true)

    name_template = build(:json_name_person, 'authorized' => false)
    values = name_template.to_hash.reject {|name, val| val.nil?}

    duplicated_name = JSONModel(:name_person).from_hash(values)
    another_duplicated_name = JSONModel(:name_person).from_hash(values)

    agent = AgentPerson.create_from_json(build(:json_agent_person,
                                               :names => [unique_name, duplicated_name, another_duplicated_name]))

    AgentPerson.to_jsonmodel(agent.id).names.length.should eq(2)
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

end
