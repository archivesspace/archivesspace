require_relative 'agent_manager'
require_relative 'name_software'

class AgentSoftware < Sequel::Model(:agent_software)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin


  one_to_many :name_software
  one_to_many :agent_contact

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_software,
                 :corresponding_to_association => :name_software,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contact,
                 :always_resolve => true)


  register_agent_type(:jsonmodel => :agent_software,
                      :name_type => :name_software,
                      :name_model => NameSoftware)

end
