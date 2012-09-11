require_relative 'agent'
require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  extend Agent

  one_to_many_relationship(:table => :name_person,
                           :class => NamePerson,
                           :type => :name,
                           :plural_type => :names)

  one_to_many_relationship(:table => :agent_contacts,
                           :class => AgentContact,
                           :type => :agent_contact,
                           :plural_type => :agent_contacts)


  define_linked_record(:type => :name_person,
                       :plural_type => :names,
                       :class => NamePerson,
                       :always_inline => true,
                       :delete_when_unassociating => true,
                       :foreign_key => :agent_person_id)


  define_linked_record(:type => :agent_contact,
                       :plural_type => :agent_contacts,
                       :class => AgentContact,
                       :always_inline => true,
                       :delete_when_unassociating => true,
                       :foreign_key => :agent_person_id)



  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.type = "Person"
    json
  end

end
