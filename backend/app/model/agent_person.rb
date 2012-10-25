require_relative 'agent_manager'
require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin


  one_to_many :name_person
  one_to_many :agent_contact

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_person,
                 :corresponding_to_association => :name_person,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contact,
                 :always_resolve => true)


  register_agent_type(:jsonmodel => :agent_person,
                      :name_type => :name_person,
                      :name_model => NamePerson)

end
