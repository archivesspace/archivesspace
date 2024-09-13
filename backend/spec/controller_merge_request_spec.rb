require 'spec_helper'

MERGEABLE_TYPES = ['subject', 'top_container', 'agent', 'resource', 'digital_object']

describe 'Merge request controller' do

  def get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    request = JSONModel(:merge_request_detail).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]
    request.selections = selections

    return request
  end

  it "can merge two subjects" do
    merge_destination = create(:json_subject)
    merge_candidate = create(:json_subject)

    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]

    request.save(:record_type => 'subject')

    expect {
      JSONModel(:subject).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  ['accession', 'digital_object', 'resource', 'archival_object', 'digital_object_component'].each do |type|
    it "can merge two subjects, but delete duplicate relationships from records" do
      merge_destination = create(:json_subject)
      merge_candidate = create(:json_subject)

      parent1 = create(:"json_#{type}",
                      :subjects => [
                        {
                          :ref => merge_candidate.uri
                        }
                       ]
                      )

      parent2 = create(:"json_#{type}",
                      :subjects => [
                        {
                          :ref => merge_destination.uri
                        },
                        {
                          :ref => merge_candidate.uri
                        }
                       ]
                      )

      # Target and merge_candidate are present
      expect(parent1.subjects.count).to eq(1)
      expect(parent2.subjects.count).to eq(2)

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'subject')

      # Victim is gone
      expect(JSONModel(:"#{type}").find(parent1.id).subjects.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects.count).to eq(1)
      # Target still there
      expect(JSONModel(:"#{type}").find(parent1.id).subjects).to include("ref" => merge_destination.uri)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects).to include("ref" => merge_destination.uri)
    end


    it "can merge two subjects, but retain and update unrelated relationships" do
      merge_destination = create(:json_subject)
      merge_candidate = create(:json_subject)

      parent1 = create(:"json_#{type}", :subjects => [
                           {
                             :ref => merge_destination.uri
                           }
                         ])

      parent2 = create(:"json_#{type}", :subjects => [
                           {
                             :ref => merge_candidate.uri
                           }
                         ])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'subject')

      # Relationships updated and merge_candidate is gone
      expect(JSONModel(:"#{type}").find(parent1.id).subjects.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).subjects).not_to include(merge_candidate)
    end


    it "can merge two agents, but delete duplicate relationships" do
      merge_destination = create(:json_agent_person)
      merge_candidate = create(:json_agent_person)

      parent = create(:"json_#{type}",
                      :linked_agents => [{
                        'ref' => merge_destination.uri,
                        'role' => 'creator'
                      },
                      {
                        'ref' => merge_candidate.uri,
                        'role' => 'creator'
                      }])

      # Target and merge_candidate are present
      expect(parent.linked_agents.count).to eq(2)

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'agent')

      # Victim and relationship are gone
      expect(JSONModel(:"#{type}").find(parent.id).linked_agents.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent.id).linked_agents).not_to include(merge_candidate)
    end


    it "can merge two agents, but retain and update unrelated relationships" do
      merge_destination = create(:json_agent_person)
      merge_candidate = create(:json_agent_person)

      parent1 = create(:"json_#{type}",
                       :linked_agents => [{
                         'ref' => merge_destination.uri,
                         'role' => 'creator'
                       }])

      parent2 = create(:"json_#{type}",
                       :linked_agents => [{
                         'ref' => merge_candidate.uri,
                         'role' => 'creator'
                       }])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'agent')

      # Relationships updated and merge_candidate is gone
      expect(JSONModel(:"#{type}").find(parent1.id).linked_agents.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).linked_agents.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).linked_agents).not_to include(merge_candidate)
    end
  end

  MERGEABLE_TYPES.each do |type|
    it "doesn't mess things up if you merge a #{type} record with itself" do
      if type == 'agent'
        agent_type = ['corporate_entity', 'family', 'person', 'software'].sample
        merge_destination = create(:"json_#{type}_#{agent_type}")
      else
        merge_destination = create(:"json_#{type}")
      end

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_destination.uri }]

      request.save(:record_type => "#{type}")

      expect {
        agent_type ? JSONModel(:"#{type}_#{agent_type}").find(merge_destination.id) : JSONModel(:"#{type}").find(merge_destination.id)
      }.not_to raise_error
    end
  end


  it "throws an error if you ask it to merge records of two different types" do
    # Gonna skip agents cause they're just more complicated than its worth
    MERGEABLE_TYPES.delete('agent')
    types = MERGEABLE_TYPES.sample(2)
    merge_destination = create(:"json_#{types[0]}")
    merge_candidate = create(:"json_#{types[1]}")

    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]

    expect {
      request.save(:record_type => "#{types[0]}")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "throws an error if you ask it to merge records belonging to different repositories" do
    ['accession', 'resource', 'digital_object', 'top_container'].each do |type|
      merge_candidate = create(:"json_#{type}")

      # New repo
      create(:repo)
      merge_destination = create(:"json_#{type}")

      request = JSONModel(:merge_request).new
      request.merge_destination = {'ref' => merge_destination.uri}
      request.merge_candidates = [{'ref' => merge_candidate.uri}]

      # Victim is gone
      expect {
        request.save(:record_type => type)
      }.to raise_error(JSONModel::ValidationException)
    end
  end


  it "can merge two agents" do
    merge_destination = create(:json_agent_person)
    merge_candidate = create(:json_agent_person)

    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]

    request.save(:record_type => 'agent')

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end


  it "can merge two agents of different types" do
    merge_destination = create(:json_agent_person)
    merge_candidate = create(:json_agent_corporate_entity)

    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]

    request.save(:record_type => 'agent')

    expect {
      JSONModel(:agent_corporate_entity).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end


  it "can merge two resources" do
    merge_destination = create(:json_resource)
    merge_candidate = create(:json_resource)

    merge_candidate_ao = create(:json_archival_object,
                       :resource => {'ref' => merge_candidate.uri})

    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]

    request.save(:record_type => 'resource')

    # Victim is gone
    expect {
      JSONModel(:resource).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)

    # The children were moved
    tree_uri = "#{merge_destination.uri}/tree/root"
    tree = JSONModel::HTTP.get_json(tree_uri)
    expect(tree['child_count']).to eq(1)
    expect(tree['precomputed_waypoints'][""]["0"][0]["uri"]).to eq(merge_candidate_ao.uri)

    # An event was created
    expect(Event.this_repo.all.any? {|event|
      expect(event.outcome_note).to match(/#{merge_candidate.title}/)
    }).to be_truthy
  end


  it "can merge two digital objects" do
    merge_destination = create(:json_digital_object)
    merge_candidate = create(:json_digital_object)

    merge_candidate_doc = create(:json_digital_object_component,
                        :digital_object => {'ref' => merge_candidate.uri})

    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]

    request.save(:record_type => 'digital_object')

    # Victim is gone
    expect {
      JSONModel(:digital_object).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)

    # The children were moved
    tree_uri = "#{merge_destination.uri}/tree/root"
    tree = JSONModel::HTTP.get_json(tree_uri)
    expect(tree['child_count']).to eq(1)
    expect(tree['precomputed_waypoints'][""]["0"][0]["uri"]).to eq(merge_candidate_doc.uri)

    # An event was created
    expect(Event.this_repo.all.any? {|event|
      expect(event.outcome_note).to match(/#{merge_candidate.title}/)
    }).to be_truthy
  end

  describe "merging agents" do
    it "can merge two agents" do
      merge_destination = create(:json_agent_person)
      merge_candidate = create(:json_agent_person)

      request = JSONModel(:merge_request).new
      request.merge_destination = {'ref' => merge_destination.uri}
      request.merge_candidates = [{'ref' => merge_candidate.uri}]

      request.save(:record_type => 'agent')

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end


    it "can merge two agents of different types" do
      merge_destination = create(:json_agent_person)
      merge_candidate = create(:json_agent_corporate_entity)

      request = JSONModel(:merge_request).new
      request.merge_destination = {'ref' => merge_destination.uri}
      request.merge_candidates = [{'ref' => merge_candidate.uri}]

      request.save(:record_type => 'agent')

      expect {
        JSONModel(:agent_corporate_entity).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end

    # In the tests below, selection hash order will determine which subrec in merge_destination is replaced
    # For example, in a replace operation the contents of selection[n] will replace merge_destination[subrecord][n]
    # Some of these tests simulate a replacement of selection[0] to merge_destination[subrecord][0]
    # Others simulate selection[1] to merge_destination[subrecord][1]

    it "can replace entire subrecord on merge" do
      merge_destination = create(:json_agent_person_merge_destination)
      merge_candidate = create(:json_agent_person_merge_candidate)
      subrecord = merge_candidate["agent_conventions_declarations"][0]

      selections = {
        'agent_conventions_declarations' => [
          {
            'replace' => "REPLACE",
            'position' => "0"
          }
        ]
      }

      merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
      merge_request.save(:record_type => 'agent_detail')

      merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
      replaced_subrecord = merge_destination_record['agent_conventions_declarations'][0]

      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end

    it "can append entire subrecord on merge" do
      merge_destination = create(:json_agent_person_merge_destination)
      merge_candidate = create(:json_agent_person_merge_candidate)
      subrecord = merge_candidate["agent_conventions_declarations"][0]
      merge_destination_subrecord_count = merge_destination['agent_conventions_declarations'].length

      selections = {
        'agent_conventions_declarations' => [
          {
            'append' => "REPLACE",
            'position' => "0"
          },
        ]
      }

      merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
      merge_request.save(:record_type => 'agent_detail')

      merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
      appended_subrecord = merge_destination_record['agent_conventions_declarations'].last

      expect(merge_destination_record['agent_conventions_declarations'].length).to eq(merge_destination_subrecord_count += 1)

      appended_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(appended_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end

    it "can replace field in subrecord on merge" do
      merge_destination = create(:json_agent_person_merge_destination)
      merge_candidate = create(:json_agent_person_merge_candidate)
      merge_destination_subrecord = merge_destination["agent_record_controls"][0]
      merge_candidate_subrecord = merge_candidate["agent_record_controls"][0]

      selections = {
        'agent_record_controls' => [
          {
            'maintenance_agency' => "REPLACE",
            'position' => "0"
          }
        ]
      }

      merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
      merge_request.save(:record_type => 'agent_detail')

      merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
      replaced_subrecord = merge_destination_record['agent_record_controls'][0]

      # replaced field
      expect(replaced_subrecord['maintenance_agency']).to eq(merge_candidate_subrecord['maintenance_agency'])

      # other fields in subrec should stay the same as before
      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "maintenance_agency" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(merge_destination_subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end

    it "can replace entire subrecord on merge when order is changed" do
      merge_destination = create(:json_agent_person_merge_destination)
      merge_candidate = create(:json_agent_person_merge_candidate)
      subrecord = merge_candidate["agent_conventions_declarations"][0]


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

      merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
      merge_request.save(:record_type => 'agent_detail')

      merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
      replaced_subrecord = merge_destination_record['agent_conventions_declarations'][1]

      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end

    it "can append entire subrecord on merge when order is changed" do
      merge_destination = create(:json_agent_person_merge_destination)
      merge_candidate = create(:json_agent_person_merge_candidate)
      subrecord = merge_candidate["agent_conventions_declarations"][0]
      merge_destination_subrecord_count = merge_destination['agent_conventions_declarations'].length

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

      merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
      merge_request.save(:record_type => 'agent_detail')

      merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
      appended_subrecord = merge_destination_record['agent_conventions_declarations'].last

      expect(merge_destination_record['agent_conventions_declarations'].length).to eq(merge_destination_subrecord_count += 1)

      appended_subrecord.each_key do |k|
        next if k == "id" || k == "agent_person_id" || k =~ /time/
        expect(appended_subrecord[k]).to eq(subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end

    it "can replace field in subrecord on merge when order is changed" do
      merge_destination = create(:json_agent_person_merge_destination)
      merge_candidate = create(:json_agent_person_merge_candidate)
      merge_destination_subrecord = merge_destination["agent_conventions_declarations"][1]
      merge_candidate_subrecord = merge_candidate["agent_conventions_declarations"][0]

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

      merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
      merge_request.save(:record_type => 'agent_detail')

      merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
      replaced_subrecord = merge_destination_record['agent_conventions_declarations'][1]

      # replaced field
      expect(replaced_subrecord['descriptive_note']).to eq(merge_candidate_subrecord['descriptive_note'])

      # other fields in subrec should stay the same as before
      replaced_subrecord.each_key do |k|
        next if k == "id" || k == "descriptive_note" || k =~ /time/
        expect(replaced_subrecord[k]).to eq(merge_destination_subrecord[k])
      end

      expect {
        JSONModel(:agent_person).find(merge_candidate.id)
      }.to raise_error(RecordNotFound)
    end
  end

  it "can merge two top containers" do
    merge_destination = create(:json_top_container)
    merge_candidate = create(:json_top_container)

    request = JSONModel(:merge_request).new
    request.merge_destination = { 'ref' => merge_destination.uri }
    request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

    request.save(:record_type => 'top_container')

    # Victim is gone
    expect {
      JSONModel(:top_container).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  it "can merge two top containers and only ever retain one container profile" do
    merge_destination_cp = create(:json_container_profile)
    merge_candidate_cp = create(:json_container_profile)

    merge_destination = create(:json_top_container,
                    :container_profile => {'ref' => merge_destination_cp.uri})
    merge_candidate = create(:json_top_container,
                    :container_profile => {'ref' => merge_candidate_cp.uri})

    # There is only one container profile and it is the merge_destination container profile
    cp = JSONModel(:top_container).find(merge_destination.id).container_profile
    expect(cp.count).to eq(1)
    expect(cp).to include("ref" => merge_destination_cp.uri)

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.merge_destination = { 'ref' => merge_destination.uri }
    request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

    request.save(:record_type => 'top_container')

    # There should still only be one container profile
    container_profile = JSONModel(:top_container).find(merge_destination.id).container_profile
    expect(container_profile.count).to eq(1)
    expect(container_profile).to include("ref" => merge_destination_cp.uri)
    expect(container_profile).not_to include("ref" => merge_candidate_cp.uri)
  end


  it "can merge two top containers and move the lone merge_candidate container profile" do
    merge_candidate_cp = create(:json_container_profile)

    merge_destination = create(:json_top_container)
    merge_candidate = create(:json_top_container,
                    :container_profile => {'ref' => merge_candidate_cp.uri})

    # No container profile here
    expect(JSONModel(:top_container).find(merge_destination.id).container_profile).to be_nil

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.merge_destination = { 'ref' => merge_destination.uri }
    request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

    request.save(:record_type => 'top_container')

    # There should be one container profile
    container_profile = JSONModel(:top_container).find(merge_destination.id).container_profile
    expect(container_profile.count).to eq(1)
    expect(container_profile).to include("ref" => merge_candidate_cp.uri)
  end


  it "can merge two top containers and move one duplicate merge_candidate container profile" do
    cp = create(:json_container_profile)

    merge_destination = create(:json_top_container)
    merge_candidate1 = create(:json_top_container,
                    :container_profile => {'ref' => cp.uri})
    merge_candidate2 = create(:json_top_container,
                    :container_profile => {'ref' => cp.uri})

    # No container profile here
    expect(JSONModel(:top_container).find(merge_destination.id).container_profile).to be_nil

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.merge_destination = { 'ref' => merge_destination.uri }
    request.merge_candidates = [{ 'ref' => merge_candidate1.uri }, { 'ref' => merge_candidate2.uri }]

    request.save(:record_type => 'top_container')

    # There should be one container profile
    container_profile = JSONModel(:top_container).find(merge_destination.id).container_profile
    expect(container_profile.count).to eq(1)
    expect(container_profile).to include("ref" => cp.uri)
  end


  it "can merge two loaded up top containers and appropriately retain/delete relationships" do
    merge_destination_cp = create(:json_container_profile)
    merge_candidate_cp = create(:json_container_profile)

    merge_destination_location = create(:json_location)
    merge_candidate_location = create(:json_location)

    merge_destination = create(:json_top_container,
                    :container_profile => {'ref' => merge_destination_cp.uri},
                    :container_locations => [{'ref' => merge_destination_location.uri,
                                              'status' => 'current',
                                              'start_date' => generate(:yyyy_mm_dd),
                                              'end_date' => generate(:yyyy_mm_dd)}]
                    )
    merge_candidate = create(:json_top_container,
                    :container_profile => {'ref' => merge_candidate_cp.uri},
                    :container_locations => [{'ref' => merge_candidate_location.uri,
                                              'status' => 'current',
                                              'start_date' => generate(:yyyy_mm_dd),
                                              'end_date' => generate(:yyyy_mm_dd)}]
                    )

    merge_destination_event = create(:json_event,
                           'linked_agents' => [
                             {'ref' => '/agents/people/1', 'role' => 'authorizer'}
                           ],
                           'linked_records' => [
                             {'ref' => merge_destination.uri, 'role' => 'source'}
                           ]
                         )
    merge_candidate_event = create(:json_event,
                           'linked_agents' => [
                             {'ref' => '/agents/people/1', 'role' => 'authorizer'}
                           ],
                           'linked_records' => [
                             {'ref' => merge_candidate.uri, 'role' => 'source'}
                           ]
                         )

    # Merge the containers
    request = JSONModel(:merge_request).new
    request.merge_destination = { 'ref' => merge_destination.uri }
    request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

    request.save(:record_type => 'top_container')

    # There should still only be one container profile
    merged_container = JSONModel(:top_container).find(merge_destination.id)
    expect(merged_container.container_profile.count).to eq(1)

    # Victim container locations are not retained
    expect(merged_container.container_locations.count).to eq(1)
    expect(merged_container.container_locations).to include(include("ref" => merge_destination_location.uri))
    expect(merged_container.container_locations).not_to include(include("ref" => merge_candidate_location.uri))

    # And event records should be updated
    event1 = JSONModel(:event).find(merge_destination_event.id)
    expect(event1.linked_records).to include(include("ref" => merge_destination.uri))
    event2 = JSONModel(:event).find(merge_candidate_event.id)
    expect(event2.linked_records).to include(include("ref" => merge_destination.uri))
    expect(event2.linked_records).not_to include(include("ref" => merge_candidate.uri))
  end


  ['accession', 'resource'].each do |type|
    it "can merge two top containers, but delete duplicate instances, subcontainers, and relationships" do
      merge_destination = create(:json_top_container)
      merge_candidate = create(:json_top_container)

      parent = create(:"json_#{type}",
                      :instances => [build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :indicator_2 => nil,
                                                             :type_2 => nil,
                                                             :indicator_3 => nil,
                                                             :type_3 => nil,
                                                             :top_container => { :ref => merge_destination.uri })),
                                  build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :indicator_2 => nil,
                                                             :type_2 => nil,
                                                             :indicator_3 => nil,
                                                             :type_3 => nil,
                                                             :top_container => { :ref => merge_candidate.uri }))])

      # Target and merge_candidate are present
      expect(parent.instances.count).to eq(2)

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'top_container')

      # Victim is gone
      expect(JSONModel(:"#{type}").find(parent.id).instances.count).to eq(1)
    end


    it "can merge two top containers, but retain instances and relationships if subcontainers are not empty" do
      merge_destination = create(:json_top_container)
      merge_candidate = create(:json_top_container)

      parent = create(:"json_#{type}",
                      :instances => [build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :top_container => { :ref => merge_destination.uri })),
                                  build(:json_instance,
                                        :sub_container => build(:json_sub_container,
                                                             :top_container => { :ref => merge_candidate.uri }))])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'top_container')

      # Two instances remain
      expect(JSONModel(:"#{type}").find(parent.id).instances.count).to eq(2)
      # But the merge_candidate uri is gone
      expect(JSONModel(:"#{type}").find(parent.id).instances).not_to include(merge_candidate.uri)
    end


    it "can merge two top containers, but retain unrelated instances, subcontainers, and relationships" do
      merge_destination = create(:json_top_container)
      merge_candidate = create(:json_top_container)

      parent1 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => merge_destination.uri }))])

      parent2 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => merge_candidate.uri }))])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'top_container')

      # Relationships updated and merge_candidate is gone
      expect(JSONModel(:"#{type}").find(parent1.id).instances.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).instances.count).to eq(1)
      expect(JSONModel(:"#{type}").find(parent2.id).instances).not_to include(merge_candidate)
    end

    it "can merge one linked, one unlinked top container without destroying merge_candidate parent record" do
      merge_destination = create(:json_top_container)
      merge_candidate = create(:json_top_container)

      parent = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => merge_candidate.uri }))])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'top_container')

      expect { JSONModel(:"#{type}").find(parent.id) }.not_to raise_error
    end

    it "can merge one linked, one unlinked top container without destroying merge_destination parent record" do
      merge_destination = create(:json_top_container)
      merge_candidate = create(:json_top_container)

      parent = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => merge_destination.uri }))])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'top_container')

      expect { JSONModel(:"#{type}").find(parent.id) }.not_to raise_error
    end

    it "can merge two linked top containers without destroying parent records" do
      merge_destination = create(:json_top_container)
      merge_candidate = create(:json_top_container)

      parent2 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => merge_destination.uri }))])

      parent1 = create(:"json_#{type}",
                       :instances => [build(:json_instance,
                                         :sub_container => build(:json_sub_container,
                                                              :indicator_2 => nil,
                                                              :type_2 => nil,
                                                              :indicator_3 => nil,
                                                              :type_3 => nil,
                                                              :top_container => { :ref => merge_candidate.uri }))])

      request = JSONModel(:merge_request).new
      request.merge_destination = { 'ref' => merge_destination.uri }
      request.merge_candidates = [{ 'ref' => merge_candidate.uri }]

      request.save(:record_type => 'top_container')

      expect { JSONModel(:"#{type}").find(parent1.id) }.not_to raise_error
      expect { JSONModel(:"#{type}").find(parent2.id) }.not_to raise_error
    end
  end
end
