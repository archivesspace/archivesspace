require_relative 'name_family'

class AgentFamily < Sequel::Model(:agent_family)

  include ASModel
  corresponds_to JSONModel(:agent_family)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes
  include Publishable


  register_agent_type(:jsonmodel => :agent_family,
                      :name_type => :name_family,
                      :name_model => NameFamily)



end
