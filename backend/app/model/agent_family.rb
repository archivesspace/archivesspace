require_relative 'agent_manager'
require_relative 'name_family'

class AgentFamily < Sequel::Model(:agent_family)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin

  register_agent_type(:jsonmodel => :agent_family,
                      :name_type => :name_family,
                      :name_model => NameFamily)
end
