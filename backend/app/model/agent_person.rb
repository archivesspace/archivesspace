require_relative 'agent'
require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  extend Agent

  one_to_many_names(:table => :name_person,
                    :class => NamePerson)

  one_to_many_contact_details

  def self.create_from_json(json, opts = {})
    obj = super(json, opts)
    apply_names(obj, json)
    apply_contact_details(obj, json, AgentContact, JSONModel(:agent_contact), opts)
    obj
  end


  def update_from_json(json, opts = {})
    obj = super(json, opts)
    apply_names(obj, json)
    apply_contact_details(obj, json, AgentContact, JSONModel(:agent_contact), opts)
    obj
  end


  def self.apply_names(agent, json, opts = {})
    opts[:agent_person_id] = agent.id
    link_names(agent, json, NamePerson, JSONModel(:name_person), opts)   
  end


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)

    json.type = "Person"
    json.names = obj.names.map {|name|
      NamePerson.to_jsonmodel(name, :name_person).to_hash
    }

    json
  end

end
