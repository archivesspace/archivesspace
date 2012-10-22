
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

class AccessionLink < Sequel::Model(:accession_link)
  many_to_one :accession
  many_to_one :event
end

class ResourceLink < Sequel::Model(:resource_link)
  many_to_one :resource
  many_to_one :event
end

class ArchivalObjectLink < Sequel::Model(:archival_object_link)
  many_to_one :archival_object
  many_to_one :event
end



class Event < Sequel::Model(:event)
  plugin :validation_helpers

  include ASModel
  Sequel.extension :inflector

  one_to_many :date, :class => "ASDate"
  jsonmodel_hint(:the_property => :date,
                 :contains_records_of_type => :date,
                 :corresponding_to_association => :date,
                 :is_array => false,
                 :always_resolve => true)

  @@agent_links = [:agent_person, :agent_corporate_entity,
                   :agent_family, :agent_software]

  @@record_links = [:accession, :resource, :archival_object]

  (@@agent_links + @@record_links).each do |link_type|
    one_to_many "#{link_type}_link".intern
  end


  def self.create_from_json(json, opts = {})
    obj = super(json, opts)
    set_agents(json, obj, opts)
    set_records(json, obj, opts)
    obj
  end


  def update_from_json(json, opts = {})
    obj = super(json, opts)
    self.class.set_agents(json, obj, opts)
    self.class.set_records(json, obj, opts)
    obj
  end


  def self.set_agents(json, obj, opts)
    @@agent_links.each do |link|
      obj.send("remove_all_#{link}_link".intern)
    end

    (json[:linked_agents] or []).each do |agent_link|
      agent_type = JSONModel.parse_reference(agent_link["ref"], opts)

      model = Kernel.const_get(agent_type[:type].camelize)
      agent = model[agent_type[:id]]

      link = Kernel.const_get("#{agent_type[:type]}_link".camelize)

      obj.send("add_#{agent_type[:type]}_link".intern,
               link.create(agent_type[:type] => agent, :event => obj, :role => agent_link["role"]))
    end
  end


  def self.set_records(json, obj, opts)
    @@record_links.each do |link|
      obj.send("remove_all_#{link}_link".intern)
    end

    (json[:linked_records] or []).each do |record_link|
      record_type = JSONModel.parse_reference(record_link["ref"], opts)

      model = Kernel.const_get(record_type[:type].camelize)
      record = model[record_type[:id]]

      link = Kernel.const_get("#{record_type[:type]}_link".camelize)

      obj.send("add_#{record_type[:type]}_link".intern,
               link.create(record_type[:type] => record, :event => obj, :role => record_link["role"]))
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

    json.linked_records = @@record_links.map {|record_type|
      obj.send("#{record_type}_link".intern).map {|link|
        {
          "role" => link[:role],
          "ref" => JSONModel(record_type).uri_for(link["#{record_type}_id".intern])
        }
      }
    }.flatten


    json
  end


end
