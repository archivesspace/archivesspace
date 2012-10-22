require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  include ExternalDocuments

  one_to_many :name_person
  one_to_many :agent_contact

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_person,
                 :corresponding_to_association => :name_person,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contact,
                 :always_resolve => true)


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super
    json.agent_type = "agent_person"
    json
  end

end
