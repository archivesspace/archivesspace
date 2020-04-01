require 'spec_helper'

MERGEABLE_TYPES = ['subject', 'top_container', 'agent', 'resource', 'digital_object']

describe 'Merge request controller' do

  it "can merge two subjects" do
    target = create(:json_subject)
    victim = create(:json_subject)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'subject')

    expect {
      JSONModel(:subject).find(victim.id)
    }.to raise_error(RecordNotFound)
  end

  ['accession', 'digital_object', 'resource', 'archival_object', 'digital_object_component'].each do |type|
    it "can merge two subjects, but delete duplicate relationships from records" do
      target = create(:json_subject)
      victim = create(:json_subject)

      parent1 = create(:"json_#{type}",
                      :subjects => [
                        {
                          :ref => victim.uri
                        }
                       ]
                      )

      parent2 = create(:"json_#{type}",
                      :subjects => [
                        {
                          :ref => target.uri
                        },
                        {
                          :ref => victim.uri
                        }
                       ]
                      )

      # Target and victim are present
      expect(parent1.subjects.count).to eq(1)
      expect(parent2.subjects.count).to eq(2)

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'subject')

      # Victim is gone
      expect(JSONModel(:"#{type}").find(parent1.id).subjects.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects.count).to eq(1)
      # Target still there
      expect(JSONModel(:"#{type}").find(parent1.id).subjects).to include("ref" => target.uri)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects).to include("ref" => target.uri)
    end


    it "can merge two subjects, but retain and update unrelated relationships" do
      target = create(:json_subject)
      victim = create(:json_subject)

      parent1 = create(:"json_#{type}", :subjects => [
                           {
                             :ref => target.uri
                           }
                         ])

      parent2 = create(:"json_#{type}", :subjects => [
                           {
                             :ref => victim.uri
                           }
                         ])

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'subject')

      # Relationships updated and victim is gone
      expect(JSONModel(:"#{type}").find(parent1.id).subjects.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects).not_to include(victim)
    end


    it "can merge two agents, but delete duplicate relationships" do
      target = create(:json_agent_person)
      victim = create(:json_agent_person)

      parent = create(:"json_#{type}",
                      :linked_agents => [{
                        'ref' => target.uri,
                        'role' => 'creator'
                      },
                      {
                        'ref' => victim.uri,
                        'role' => 'creator'
                      }])

      # Target and victim are present
      expect(parent.linked_agents.count).to eq(2)

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'agent')

      # Victim and relationship are gone
      expect(JSONModel(:"#{type}").find(parent.id).linked_agents.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent.id).linked_agents).not_to include(victim)
    end


    it "can merge two agents, but retain and update unrelated relationships" do
      target = create(:json_agent_person)
      victim = create(:json_agent_person)

      parent1 = create(:"json_#{type}",
                       :linked_agents => [{
                         'ref' => target.uri,
                         'role' => 'creator'
                       }])

      parent2 = create(:"json_#{type}",
                       :linked_agents => [{
                         'ref' => victim.uri,
                         'role' => 'creator'
                       }])

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'agent')

      # Relationships updated and victim is gone
      expect(JSONModel(:"#{type}").find(parent1.id).linked_agents.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).linked_agents.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).linked_agents).not_to include(victim)
    end
  end

  MERGEABLE_TYPES.each do |type|
    it "doesn't mess things up if you merge a #{type} record with itself" do
      if type == 'agent'
        agent_type = ['corporate_entity', 'family', 'person', 'software'].sample
        target = create(:"json_#{type}_#{agent_type}")
      else
        target = create(:"json_#{type}")
      end

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => target.uri }]

      request.save(:record_type => "#{type}")

      expect {
        agent_type ? JSONModel(:"#{type}_#{agent_type}").find(target.id) : JSONModel(:"#{type}").find(target.id)
      }.not_to raise_error
    end
  end


  it "throws an error if you ask it to merge records of two different types" do
    # Gonna skip agents cause they're just more complicated than its worth
    MERGEABLE_TYPES.delete('agent')
    types = MERGEABLE_TYPES.sample(2)
    target = create(:"json_#{types[0]}")
    victim = create(:"json_#{types[1]}")

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    expect {
      request.save(:record_type => "#{types[0]}")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "throws an error if you ask it to merge records belonging to different repositories" do
    ['accession', 'resource', 'digital_object', 'top_container'].each do |type|
      victim = create(:"json_#{type}")

      # New repo
      create(:repo)
      target = create(:"json_#{type}")

      request = JSONModel(:merge_request).new
      request.target = {'ref' => target.uri}
      request.victims = [{'ref' => victim.uri}]

      # Victim is gone
      expect {
        request.save(:record_type => type)
      }.to raise_error(JSONModel::ValidationException)
    end
  end


  it "can merge two agents" do
    target = create(:json_agent_person)
    victim = create(:json_agent_person)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'agent')

    expect {
      JSONModel(:agent_person).find(victim.id)
    }.to raise_error(RecordNotFound)
  end


  it "can merge two agents of different types" do
    target = create(:json_agent_person)
    victim = create(:json_agent_corporate_entity)

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'agent')

    expect {
      JSONModel(:agent_corporate_entity).find(victim.id)
    }.to raise_error(RecordNotFound)
  end


  it "can merge two resources" do
    target = create(:json_resource)
    victim = create(:json_resource)

    victim_ao = create(:json_archival_object,
                       :resource => {'ref' => victim.uri})

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'resource')

    # Victim is gone
    expect {
      JSONModel(:resource).find(victim.id)
    }.to raise_error(RecordNotFound)

    # The children were moved
    merged_tree = JSONModel(:resource_tree).find(nil, :resource_id => target.id)
    expect(merged_tree.children.any? {|child| child['record_uri'] == victim_ao.uri}).to be_truthy

    # An event was created
    expect(Event.this_repo.all.any? {|event|
      expect(event.outcome_note).to match(/#{victim.title}/)
    }).to be_truthy
  end


  it "can merge two digital objects" do
    target = create(:json_digital_object)
    victim = create(:json_digital_object)

    victim_doc = create(:json_digital_object_component,
                        :digital_object => {'ref' => victim.uri})

    request = JSONModel(:merge_request).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]

    request.save(:record_type => 'digital_object')

    # Victim is gone
    expect {
      JSONModel(:digital_object).find(victim.id)
    }.to raise_error(RecordNotFound)

    # The children were moved
    merged_tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => target.id)
    expect(merged_tree.children.any? {|child| child['record_uri'] == victim_doc.uri}).to be_truthy

    # An event was created
    expect(Event.this_repo.all.any? {|event|
      expect(event.outcome_note).to match(/#{victim.title}/)
    }).to be_truthy
  end


  it "can merge two top containers" do
    target = create(:json_top_container)
    victim = create(:json_top_container)

    request = JSONModel(:merge_request).new
    request.target = { 'ref' => target.uri }
    request.victims = [{ 'ref' => victim.uri }]

    request.save(:record_type => 'top_container')

    # Victim is gone
    expect {
      JSONModel(:top_container).find(victim.id)
    }.to raise_error(RecordNotFound)
  end


  ['accession', 'resource'].each do |type|
    it "can merge two top containers, but delete duplicate instances, subcontainers, and relationships" do
      target = create(:json_top_container)
      victim = create(:json_top_container)

      parent = create(:"json_#{type}",
                      :instances => [build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :indicator_2 => nil,
                                                             :type_2 => nil,
                                                             :indicator_3 => nil,
                                                             :type_3 => nil,
                                                             :top_container => { :ref => target.uri })),
                                  build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :indicator_2 => nil,
                                                             :type_2 => nil,
                                                             :indicator_3 => nil,
                                                             :type_3 => nil,
                                                             :top_container => { :ref => victim.uri }))])

      # Target and victim are present
      expect(parent.instances.count).to eq(2)

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'top_container')

      # Victim is gone
      expect(JSONModel(:"#{type}").find(parent.id).instances.count).to eq(1)
    end


    it "can merge two top containers, but retain instances and relationships if subcontainers are not empty" do
      target = create(:json_top_container)
      victim = create(:json_top_container)

      parent = create(:"json_#{type}",
                      :instances => [build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :top_container => { :ref => target.uri })),
                                  build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :top_container => { :ref => victim.uri }))])

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'top_container')

      # Two instances remain
      expect(JSONModel(:"#{type}").find(parent.id).instances.count).to eq(2)
      # But the victim uri is gone
      expect(JSONModel(:"#{type}").find(parent.id).instances).not_to include(victim.uri)
    end


    it "can merge two top containers, but retain unrelated instances, subcontainers, and relationships" do
      target = create(:json_top_container)
      victim = create(:json_top_container)

      parent1 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => target.uri }))])

      parent2 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => victim.uri }))])

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'top_container')

      # Relationships updated and victim is gone
      expect(JSONModel(:"#{type}").find(parent1.id).instances.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).instances.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).instances).not_to include(victim)
    end
  end
end
