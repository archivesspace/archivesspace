require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel

  one_to_many :name_person
  one_to_many :agent_contacts

  jsonmodel_hint(:the_property => :names,
                 :contains_records_of_type => :name_person,
                 :corresponding_to_association => :name_person,
                 :always_resolve => true)

  jsonmodel_hint(:the_property => :agent_contacts,
                 :contains_records_of_type => :agent_contact,
                 :corresponding_to_association => :agent_contacts,
                 :always_resolve => true)


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.agent_type = "agent_person"
    json
  end

end
