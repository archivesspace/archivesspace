require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  corresponds_to JSONModel(:agent_person)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes
  include Publishable
  include Assessments::LinkedAgent

  register_agent_type(:jsonmodel => :agent_person,
                      :name_type => :name_person,
                      :name_model => NamePerson)

end
