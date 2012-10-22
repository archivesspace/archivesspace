require_relative 'name_corporate_entity'

class AgentCorporateEntity < Sequel::Model(:agent_corporate_entity)

  include ASModel
  include ExternalDocuments

  one_to_many :name_corporate_entity
  one_to_many :agent_contact

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_corporate_entity,
                 :corresponding_to_association => :name_corporate_entity,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contact,
                 :always_resolve => true)


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super
    json.agent_type = "agent_corporate_entity"
    json
  end

end
