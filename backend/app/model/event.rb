require_relative 'relationships'

class Event < Sequel::Model(:event)

  include ASModel
  corresponds_to JSONModel(:event)

  include Relationships
  include Agents

  agent_role_enum("linked_agent_event_roles")

  set_model_scope :repository

  enable_suppression

  one_to_many :date, :class => "ASDate"
  def_nested_record(:the_property => :date,
                    :contains_records_of_type => :date,
                    :corresponding_to_association => :date,
                    :is_array => false,
                    :always_resolve => true)

  define_relationship(:name => :link,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject, DigitalObject, AgentPerson, AgentCorporateEntity, AgentFamily, AgentSoftware]},
                      :class_callback => proc { |clz|
                        clz.instance_eval do
                          include DynamicEnums

                          uses_enums({
                                       :property => 'role',
                                       :uses_enum => 'linked_event_archival_record_roles'
                                     })
                        end
                      })


  def has_active_linked_records?
    linked_records(:link).each do |linked_record|
      if linked_record.values.has_key?(:suppressed) && linked_record[:suppressed] == 0
        return true
      end
    end

    return false
  end


  # Look for events that link to a given record.  If we find any, consider
  # suppressing them if they have no active linked records
  def self.handle_suppressed(record)
    events = instances_relating_to(record)

    events.each do |event|
      val = !event.has_active_linked_records?
      event.set_suppressed(val)
    end
  end


  def set_suppressed(suppress)
    self.suppressed = (suppress ? 1 : 0)
    save

    suppress
  end

end
