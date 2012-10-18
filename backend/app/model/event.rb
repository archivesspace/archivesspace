
class AgentPersonLink < Sequel::Model(:agent_person_link)
  many_to_one :agent_person
  many_to_one :event
end

class AgentCorporateEntityLink < Sequel::Model(:agent_corporate_entity_link)
  many_to_one :agent_corporate_entity
  many_to_one :event
end

class AgentFamilyLink < Sequel::Model(:agent_family_link)
  many_to_one :agent_family
  many_to_one :event
end

class AgentSoftwareLink < Sequel::Model(:agent_software_link)
  many_to_one :agent_software
  many_to_one :event
end


class Event < Sequel::Model(:events)
  plugin :validation_helpers

  include ASModel
  Sequel.extension :inflector

  one_to_many :dates, :class => "ASDate"
  jsonmodel_hint(:the_property => :date,
                 :contains_records_of_type => :date,
                 :corresponding_to_association => :dates,
                 :is_array => false,
                 :always_resolve => true)

  @@agent_links = [:agent_person, :agent_corporate_entity,
                   :agent_family, :agent_software]

  @@agent_links.each do |link_type|
    one_to_many "#{link_type}_link".intern
  end


  def self.create_from_json(json, opts = {})
    obj = super(json, opts)
    set_agents(json, obj, opts)
    obj
  end


  def update_from_json(json, opts = {})
    obj = super(json, opts)
    self.class.set_agents(json, obj, opts)
    obj
  end


  def self.set_agents(json, obj, opts)
    @@agent_links.each do |link|
      obj.send("remove_all_#{link}_link".intern)
    end

    (json[:linked_agents] or []).each do |agent_link|
      agent_type = JSONModel.parse_reference(agent_link["ref"], opts)
      # obj.add_agent_link(AgentLink.create(

      model = Kernel.const_get(agent_type[:type].camelize)
      agent = model[agent_type[:id]]

      link = Kernel.const_get("#{agent_type[:type]}_link".camelize)

      obj.send("add_#{agent_type[:type]}_link".intern,
               link.create(agent_type[:type] => agent, :event => obj, :role => agent_link["role"]))
    end
  end

  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super(obj, type)

    json.linked_agents = @@agent_links.map {|agent_type|
      obj.send("#{agent_type}_link".intern).map {|link|
        {
          "role" => link[:role],
          "ref" => JSONModel(agent_type).uri_for(link["#{agent_type}_id".intern])
        }
      }
    }.flatten

    json
  end


  # one_to_many :resource_link
  # one_to_many :archival_object_link
  # one_to_many :accession_link
end
