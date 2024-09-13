require 'time'

class Event < Sequel::Model(:event)

  include ASModel
  corresponds_to JSONModel(:event)

  include Agents
  include ExternalDocuments
  include ExternalIDs

  agent_role_enum("linked_agent_event_roles")

  set_model_scope :repository
  allow_in_global_repo

  enable_suppression

  one_to_many :date, :class => "ASDate"
  def_nested_record(:the_property => :date,
                    :contains_records_of_type => :date,
                    :corresponding_to_association => :date,
                    :is_array => false)

  define_relationship(:name => :event_link,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject, DigitalObject, AgentPerson, AgentCorporateEntity, AgentFamily, AgentSoftware, DigitalObjectComponent, TopContainer]},
                      :class_callback => proc { |clz|

                        clz.instance_eval do
                          include DynamicEnums

                          uses_enums({
                                       :property => 'role',
                                       :uses_enum => ['linked_event_archival_record_roles']
                                     })
                        end
                      })


  def has_active_linked_records?
    self.related_records(:event_link).each do |linked_record|
      if linked_record.values.has_key?(:suppressed) && linked_record[:suppressed] == 0
        return true
      end
    end

    return false
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.each do |json|
      if json['timestamp']
        json['timestamp'] = json['timestamp'].iso8601
      end
    end

    jsons
  end


  #
  # Some canned creators for system generated events
  #

  def self.for_component_transfer(archival_object_uri, source_resource_uri, merge_destination_resource_uri)
    # first get the current user
    user = User[:username => RequestContext.get(:current_username)]

    # build event
    event = JSONModel(:event).from_hash({
                                          "event_type" => "component_transfer",
                                          "timestamp" => Time.now.utc.iso8601,
                                          "linked_records" => [
                                            {"role" => "source", "ref" => source_resource_uri},
                                            {"role" => "outcome", "ref" => merge_destination_resource_uri},
                                            {"role" => "transfer", "ref" => archival_object_uri},
                                          ],
                                          "linked_agents" => [
                                            {"role" => "implementer", "ref" => JSONModel(:agent_person).uri_for(user.agent_record_id)}
                                          ]
                                        })

    # save the event to the DB in the global context
    self.create_from_json(event, :system_generated => true)
  end


  def self.for_cataloging(agent_uri, record_uri)
    #build event
    event = JSONModel(:event).from_hash(
      :linked_agents => [{:ref => agent_uri, :role => 'implementer'}],
      :event_type => 'cataloged',
      :timestamp => Time.now.utc.iso8601,
      :linked_records => [{:ref => record_uri, :role => 'outcome'}]
    )


    RequestContext.in_global_repo do
      Event.create_from_json(event, :system_generated => true)
    end
  end


  def self.for_archival_record_merge(merge_destination, merge_candidates)
    user = User[:username => RequestContext.get(:current_username)]

    merge_note = ""
    merge_candidates.each do |merge_candidate|
      merge_candidate_json = merge_candidate.class.to_jsonmodel(merge_candidate)

      if merge_candidate_json['identifier']
        identifier = Identifiers.format(Identifiers.parse(merge_candidate_json['identifier']))
      else
        identifier = merge_candidate_json['digital_object_id']
      end

      merge_note += (identifier +
                     " -- " +
                     merge_candidate_json['title'] +
                     "\n")
    end

    event = JSONModel(:event).from_hash(
      :linked_agents => [{
                           "role" => "implementer",
                           "ref" => JSONModel(:agent_person).uri_for(user.agent_record_id)
                         }],
      :event_type => 'component_transfer',
      :outcome => 'pass',
      :outcome_note => merge_note,
      :timestamp => Time.now.utc.iso8601,
      :linked_records => [{:ref => merge_destination.uri, :role => 'outcome'}]
    )

    Event.create_from_json(event, :system_generated => true)
  end


  def self.for_repository_transfer(old_repo, new_repo, record)
    event = {
      :linked_agents => [
                         {
                           "role" => "transmitter",
                           "ref" => JSONModel(:agent_corporate_entity).uri_for(old_repo.agent_representation_id)
                         },
                         {
                           "role" => "recipient",
                           "ref" => JSONModel(:agent_corporate_entity).uri_for(new_repo.agent_representation_id)
                         }
                        ].reject {|l| l['ref'].nil?},
      :linked_records => [
                          {
                            "role" => "transfer",
                            "ref" => record.uri
                          }
                         ],
      :event_type => 'custody_transfer',
      :timestamp => Time.now.utc.iso8601,
    }

    Event.create_from_json(JSONModel(:event).from_hash(event), :system_generated => true)
  end


end
