require_relative 'agent_mixin'
require_relative 'name_family'

class AgentFamily < Sequel::Model(:agent_family)

  extend AgentMixin
  include ASModel
  include ExternalDocuments

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


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super
    json.agent_type = "agent_family"
    json
  end


  def self.records_matching(query, max = 10)
    self.agents_matching(query, max, :name_family, NameFamily)
  end

end
