require_relative 'agent_manager'
require_relative 'name_corporate_entity'
require_relative 'recordable_cataloging'

class AgentCorporateEntity < Sequel::Model(:agent_corporate_entity)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging

  corresponds_to JSONModel(:agent_corporate_entity)

  register_agent_type(:jsonmodel => :agent_corporate_entity,
                      :name_type => :name_corporate_entity,
                      :name_model => NameCorporateEntity)
                      

end
