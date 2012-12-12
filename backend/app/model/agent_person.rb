require_relative 'agent_manager'
require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin

  corresponds_to JSONModel(:agent_person)

  register_agent_type(:jsonmodel => :agent_person,
                      :name_type => :name_person,
                      :name_model => NamePerson)
end
