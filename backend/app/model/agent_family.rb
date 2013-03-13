require_relative 'agent_manager'
require_relative 'name_family'
require_relative 'recordable_cataloging'

class AgentFamily < Sequel::Model(:agent_family)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging

  corresponds_to JSONModel(:agent_family)

  register_agent_type(:jsonmodel => :agent_family,
                      :name_type => :name_family,
                      :name_model => NameFamily)



end
