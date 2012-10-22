["agent_contact", "agent_corporate_entity", "agent_family", "agent_person", "agent_software",
 "accession", "resource", "archival_object"].each do |dep|
  require_relative dep
end


class AgentPersonLink < Sequel::Model(:event_agent_person)
  many_to_one :agent_person
  many_to_one :event
end

class AgentCorporateEntityLink < Sequel::Model(:event_agent_corporate_entity)
  many_to_one :agent_corporate_entity
  many_to_one :event
end

class AgentFamilyLink < Sequel::Model(:event_agent_family)
  many_to_one :agent_family
  many_to_one :event
end

class AgentSoftwareLink < Sequel::Model(:event_agent_software)
  many_to_one :agent_software
  many_to_one :event
end

class AccessionLink < Sequel::Model(:event_accession)
  many_to_one :accession
  many_to_one :event
end

class ResourceLink < Sequel::Model(:event_resource)
  many_to_one :resource
  many_to_one :event
end

class ArchivalObjectLink < Sequel::Model(:event_archival_object)
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

  @@agent_links = {
    :agent_person => AgentPerson,
    :agent_corporate_entity => AgentCorporateEntity,
    :agent_family => AgentFamily,
    :agent_software => AgentSoftware
  }

  @@record_links = {
    :accession => Accession,
    :resource => Resource,
    :archival_object => ArchivalObject
  }


  (@@agent_links.keys + @@record_links.keys).each do |link_type|
    one_to_many "#{link_type}_link".intern
  end


  def self.linkable_records_for(prefix)
    @@record_links.map {|record_type, record_model|
      [record_type, record_model.records_matching(prefix, 10)]
    }
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


  def self.set_linked_records(json, obj, opts, json_property, linkable_records)
    linkable_records.keys.each do |link|
      obj.send("remove_all_#{link}_link".intern)
    end

    (json[json_property] or []).each do |record_link|
      record_type = JSONModel.parse_reference(record_link["ref"], opts)

      model = Kernel.const_get(record_type[:type].camelize)
      record = model[record_type[:id]]

      link = Kernel.const_get("#{record_type[:type]}_link".camelize)

      obj.send("add_#{record_type[:type]}_link".intern,
               link.create(record_type[:type] => record,
                           :event => obj,
                           :role => record_link["role"]))
    end

  end


  def self.set_agents(json, obj, opts)
    self.set_linked_records(json, obj, opts, :linked_agents, @@agent_links)
  end


  def self.set_records(json, obj, opts)
    self.set_linked_records(json, obj, opts, :linked_records, @@record_links)
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super(obj, type)

    [[:linked_agents, @@agent_links], [:linked_records, @@record_links]].each do |property, linked_records|
      json[property] = linked_records.keys.map {|record_type|
        obj.send("#{record_type}_link".intern).map {|link|
          {
            "role" => link[:role],
            "ref" => JSONModel(record_type).uri_for(link["#{record_type}_id".intern])
          }
        }
      }.flatten
    end


    json
  end


end
