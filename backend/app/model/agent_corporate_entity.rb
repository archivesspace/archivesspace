require_relative 'agent_manager'
require_relative 'name_corporate_entity'

class AgentCorporateEntity < Sequel::Model(:agent_corporate_entity)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin


  one_to_many :name_corporate_entity
  one_to_many :agent_contact

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_corporate_entity,
                 :corresponding_to_association => :name_corporate_entity,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contact,
                 :always_resolve => true)


  register_agent_type(:jsonmodel => :agent_corporate_entity,
                      :name_type => :name_corporate_entity,
                      :name_model => NameCorporateEntity)

end
