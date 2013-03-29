require_relative 'agent_manager'
require_relative 'name_software'
require_relative 'recordable_cataloging'
require_relative 'notes'

class AgentSoftware < Sequel::Model(:agent_software)

  include ASModel
  corresponds_to JSONModel(:agent_software)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes


  register_agent_type(:jsonmodel => :agent_software,
                      :name_type => :name_software,
                      :name_model => NameSoftware)
                      

end
