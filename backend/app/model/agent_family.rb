require_relative 'agent_manager'
require_relative 'name_family'

class AgentFamily < Sequel::Model(:agent_family)

  include ASModel
  include ExternalDocuments
  include AgentManager::Mixin


  one_to_many :name_family
  one_to_many :agent_contact

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_family,
                 :corresponding_to_association => :name_family,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contact,
                 :always_resolve => true)


  register_agent_type(:jsonmodel => :agent_family,
                      :name_type => :name_family,
                      :name_model => NameFamily)


end
