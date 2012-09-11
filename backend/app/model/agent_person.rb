require_relative 'agent'
require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  extend Agent

  one_to_many :name_person
  one_to_many :agent_contacts

  link_association_to_jsonmodel(:association => :name_person,
                                :jsonmodel => :name_person,
                                :json_property => :names,
                                :always_resolve => true)

  link_association_to_jsonmodel(:association => :agent_contacts,
                                :jsonmodel => :agent_contact,
                                :json_property => :agent_contacts,
                                :always_resolve => true)

  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.type = "Person"
    json
  end

end
