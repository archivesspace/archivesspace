require_relative 'name_software'

class AgentSoftware < Sequel::Model(:agent_software)

  include ASModel
  include ExternalDocuments

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


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super
    json.agent_type = "agent_software"
    json
  end

end
