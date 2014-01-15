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


  it "requires a rules to be set if source is not provided" do

    expect { n1 = build(:json_name_person, :rules => nil).to_hash }.to raise_error(JSONModel::ValidationException)

  end


  it "requires a source to be set if an authority id is provided, but only in strict mode" do

    expect { n1 = build(:json_name_person, :authority_id => 'wooo').to_hash }.to raise_error(JSONModel::ValidationException)

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

end
