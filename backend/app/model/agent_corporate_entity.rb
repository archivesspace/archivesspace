require_relative 'name_corporate_entity'

class AgentCorporateEntity < Sequel::Model(:agent_corporate_entity)

  include ASModel
  corresponds_to JSONModel(:agent_corporate_entity)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes


  register_agent_type(:jsonmodel => :agent_corporate_entity,
                      :name_type => :name_corporate_entity,
                      :name_model => NameCorporateEntity)
                      

end
