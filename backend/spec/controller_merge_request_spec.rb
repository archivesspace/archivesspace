require 'spec_helper'

MERGEABLE_TYPES = ['subject', 'top_container', 'agent', 'resource', 'digital_object']

describe 'Merge request controller' do

  def get_merge_request_detail_json(target, victim, selections)
    request = JSONModel(:merge_request_detail).new
    request.target = {'ref' => target.uri}
    request.victims = [{'ref' => victim.uri}]
    request.selections = selections

    return request
  end

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

  describe "merging agents" do
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

    # In the tests below, selection hash order will determine which subrec in target is replaced
    # For example, in a replace operation the contents of selection[n] will replace target[subrecord][n]
    # Some of these tests simulate a replacement of selection[0] to target[subrecord][0]
    # Others simulate selection[1] to target[subrecord][1]

    it "can replace entire subrecord on merge" do
      target = create(:json_agent_person_merge_target)
      victim = create(:json_agent_person_merge_victim)
      subrecord = victim["agent_conventions_declarations"][0]

      selections = {
        'agent_conventions_declarations' => [
          {
            'replace' => "REPLACE",
            'position' => "0"
          }
        ]
      }

      merge_request = get_merge_request_detail_json(target, victim, selections)
      merge_request.save(:record_type => 'agent_detail')

      target_record = JSONModel(:agent_person).find(target.id)
      replaced_subrecord = target_record['agent_conventions_declarations'][0]

      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(victim.id)
      }.to raise_error(RecordNotFound)
    end

    it "can append entire subrecord on merge" do
      target = create(:json_agent_person_merge_target)
      victim = create(:json_agent_person_merge_victim)
      subrecord = victim["agent_conventions_declarations"][0]
      target_subrecord_count = target['agent_conventions_declarations'].length

      selections = {
        'agent_conventions_declarations' => [
          {
            'append' => "REPLACE",
            'position' => "0"
          },
        ]
      }

      merge_request = get_merge_request_detail_json(target, victim, selections)
      merge_request.save(:record_type => 'agent_detail')

      target_record = JSONModel(:agent_person).find(target.id)
      appended_subrecord = target_record['agent_conventions_declarations'].last

      expect(target_record['agent_conventions_declarations'].length).to eq(target_subrecord_count += 1)

      appended_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(appended_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(victim.id)
      }.to raise_error(RecordNotFound)
    end

    it "can replace field in subrecord on merge" do
      target = create(:json_agent_person_merge_target)
      victim = create(:json_agent_person_merge_victim)
      target_subrecord = target["agent_record_controls"][0]
      victim_subrecord = victim["agent_record_controls"][0]

      selections = {
        'agent_record_controls' => [
          {
            'maintenance_agency' => "REPLACE",
            'position' => "0"
          }
        ]
      }

      merge_request = get_merge_request_detail_json(target, victim, selections)
      merge_request.save(:record_type => 'agent_detail')

      target_record = JSONModel(:agent_person).find(target.id)
      replaced_subrecord = target_record['agent_record_controls'][0]

      # replaced field
      expect(replaced_subrecord['maintenance_agency']).to eq(victim_subrecord['maintenance_agency'])

      # other fields in subrec should stay the same as before
      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "maintenance_agency" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(target_subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(victim.id)
      }.to raise_error(RecordNotFound)
    end

    it "can replace entire subrecord on merge when order is changed" do
      target = create(:json_agent_person_merge_target)
      victim = create(:json_agent_person_merge_victim)
      subrecord = victim["agent_conventions_declarations"][0]


      selections = {
        'agent_conventions_declarations' => [
          {
            'position' => "1"
          },
          {
            'replace' => "REPLACE",
            'position' => "0"
          }
        ]
      }

      merge_request = get_merge_request_detail_json(target, victim, selections)
      merge_request.save(:record_type => 'agent_detail')

      target_record = JSONModel(:agent_person).find(target.id)
      replaced_subrecord = target_record['agent_conventions_declarations'][1]

      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(victim.id)
      }.to raise_error(RecordNotFound)
    end

    it "can append entire subrecord on merge when order is changed" do
      target = create(:json_agent_person_merge_target)
      victim = create(:json_agent_person_merge_victim)
      subrecord = victim["agent_conventions_declarations"][0]
      target_subrecord_count = target['agent_conventions_declarations'].length

      selections = {
        'agent_conventions_declarations' => [
          {
            'position' => "1"
          },
          {
            'append' => "REPLACE",
            'position' => "0"
          },
        ]
      }

      merge_request = get_merge_request_detail_json(target, victim, selections)
      merge_request.save(:record_type => 'agent_detail')

      target_record = JSONModel(:agent_person).find(target.id)
      appended_subrecord = target_record['agent_conventions_declarations'].last

      expect(target_record['agent_conventions_declarations'].length).to eq(target_subrecord_count += 1)

      appended_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(appended_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(victim.id)
      }.to raise_error(RecordNotFound)
    end

    it "can replace field in subrecord on merge when order is changed" do
      target = create(:json_agent_person_merge_target)
      victim = create(:json_agent_person_merge_victim)
      target_subrecord = target["agent_conventions_declarations"][1]
      victim_subrecord = victim["agent_conventions_declarations"][0]

      selections = {
        'agent_conventions_declarations' => [
          {
            'position' => "1"
          },
          {
            'descriptive_note' => "REPLACE",
            'position' => "0"
          }
        ]
      }

      merge_request = get_merge_request_detail_json(target, victim, selections)
      merge_request.save(:record_type => 'agent_detail')

      target_record = JSONModel(:agent_person).find(target.id)
      replaced_subrecord = target_record['agent_conventions_declarations'][1]

      # replaced field
      expect(replaced_subrecord['descriptive_note']).to eq(victim_subrecord['descriptive_note'])

      # other fields in subrec should stay the same as before
      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "descriptive_note" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(target_subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(victim.id)
      }.to raise_error(RecordNotFound)
    end
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

  it "can merge two top containers and only ever retain one container profile" do
    target_cp = create(:json_container_profile)
    victim_cp = create(:json_container_profile)

    target = create(:json_top_container,
                    :container_profile => {'ref' => target_cp.uri})
    victim = create(:json_top_container,
                    :container_profile => {'ref' => victim_cp.uri})

    # There is only one container profile and it is the target container profile
    cp = JSONModel(:top_container).find(target.id).container_profile
    expect(cp.count).to eq(1)
    expect(cp).to include("ref" => target_cp.uri)

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.target = { 'ref' => target.uri }
    request.victims = [{ 'ref' => victim.uri }]

    request.save(:record_type => 'top_container')

    # There should still only be one container profile
    container_profile = JSONModel(:top_container).find(target.id).container_profile
    expect(container_profile.count).to eq(1)
    expect(container_profile).to include("ref" => target_cp.uri)
    expect(container_profile).not_to include("ref" => victim_cp.uri)
  end


  it "can merge two top containers and move the lone victim container profile" do
    victim_cp = create(:json_container_profile)

    target = create(:json_top_container)
    victim = create(:json_top_container,
                    :container_profile => {'ref' => victim_cp.uri})

    # No container profile here
    expect(JSONModel(:top_container).find(target.id).container_profile).to be_nil

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.target = { 'ref' => target.uri }
    request.victims = [{ 'ref' => victim.uri }]

    request.save(:record_type => 'top_container')

    # There should be one container profile
    container_profile = JSONModel(:top_container).find(target.id).container_profile
    expect(container_profile.count).to eq(1)
    expect(container_profile).to include("ref" => victim_cp.uri)
  end


  it "can merge two top containers and move one duplicate victim container profile" do
    cp = create(:json_container_profile)

    target = create(:json_top_container)
    victim1 = create(:json_top_container,
                    :container_profile => {'ref' => cp.uri})
    victim2 = create(:json_top_container,
                    :container_profile => {'ref' => cp.uri})

    # No container profile here
    expect(JSONModel(:top_container).find(target.id).container_profile).to be_nil

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.target = { 'ref' => target.uri }
    request.victims = [{ 'ref' => victim1.uri }, { 'ref' => victim2.uri }]

    request.save(:record_type => 'top_container')

    # There should be one container profile
    container_profile = JSONModel(:top_container).find(target.id).container_profile
    expect(container_profile.count).to eq(1)
    expect(container_profile).to include("ref" => cp.uri)
  end


  it "can merge two loaded up top containers and appropriately retain/delete relationships" do
    target_cp = create(:json_container_profile)
    victim_cp = create(:json_container_profile)

    target_location = create(:json_location)
    victim_location = create(:json_location)

    target = create(:json_top_container,
                    :container_profile => {'ref' => target_cp.uri},
                    :container_locations => [{'ref' => target_location.uri,
                                              'status' => 'current',
                                              'start_date' => generate(:yyyy_mm_dd),
                                              'end_date' => generate(:yyyy_mm_dd)}]
                    )
    victim = create(:json_top_container,
                    :container_profile => {'ref' => victim_cp.uri},
                    :container_locations => [{'ref' => victim_location.uri,
                                              'status' => 'current',
                                              'start_date' => generate(:yyyy_mm_dd),
                                              'end_date' => generate(:yyyy_mm_dd)}]
                    )

    target_event = create(:json_event,
                           'linked_agents' => [
                             {'ref' => '/agents/people/1', 'role' => 'authorizer'}
                           ],
                           'linked_records' => [
                             {'ref' => target.uri, 'role' => 'source'}
                           ]
                         )
    victim_event = create(:json_event,
                           'linked_agents' => [
                             {'ref' => '/agents/people/1', 'role' => 'authorizer'}
                           ],
                           'linked_records' => [
                             {'ref' => victim.uri, 'role' => 'source'}
                           ]
                         )

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.target = { 'ref' => target.uri }
    request.victims = [{ 'ref' => victim.uri }]

    request.save(:record_type => 'top_container')

    # There should still only be one container profile
    merged_container = JSONModel(:top_container).find(target.id)
    expect(merged_container.container_profile.count).to eq(1)

    # Victim container locations are not retained
    expect(merged_container.container_locations.count).to eq(1)
    expect(merged_container.container_locations).to include(include("ref" => target_location.uri))
    expect(merged_container.container_locations).not_to include(include("ref" => victim_location.uri))

    # And event records should be updated
    event1 = JSONModel(:event).find(target_event.id)
    expect(event1.linked_records).to include(include("ref" => target.uri))
    event2 = JSONModel(:event).find(victim_event.id)
    expect(event2.linked_records).to include(include("ref" => target.uri))
    expect(event2.linked_records).not_to include(include("ref" => victim.uri))
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

    it "can merge one linked, one unlinked top container without destroying victim parent record" do
      target = create(:json_top_container)
      victim = create(:json_top_container)

      parent = create(:"json_#{type}",
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

      expect { JSONModel(:"#{type}").find(parent.id) }.not_to raise_error
    end

    it "can merge one linked, one unlinked top container without destroying target parent record" do
      target = create(:json_top_container)
      victim = create(:json_top_container)

      parent = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => target.uri }))])

      request = JSONModel(:merge_request).new
      request.target = { 'ref' => target.uri }
      request.victims = [{ 'ref' => victim.uri }]

      request.save(:record_type => 'top_container')

      expect { JSONModel(:"#{type}").find(parent.id) }.not_to raise_error
    end

    it "can merge two linked top containers without destroying parent records" do
      target = create(:json_top_container)
      victim = create(:json_top_container)

      parent2 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => target.uri }))])

      parent1 = create(:"json_#{type}",
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

      expect { JSONModel(:"#{type}").find(parent1.id) }.not_to raise_error
      expect { JSONModel(:"#{type}").find(parent2.id) }.not_to raise_error
    end
  end
end
