require_relative 'agent_manager'
require_relative 'name_family'
require_relative 'recordable_cataloging'
require_relative 'notes'

class AgentFamily < Sequel::Model(:agent_family)

  include ASModel
  corresponds_to JSONModel(:agent_family)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes


  register_agent_type(:jsonmodel => :agent_family,
                      :name_type => :name_family,
                      :name_model => NameFamily)



end
