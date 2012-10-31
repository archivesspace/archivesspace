# Handling for models that link to agents
["agent_contact", "agent_corporate_entity", "agent_family", "agent_person", "agent_software"].each do |dep|
  # require dependent classes
  require_relative dep

  [ "event",
    "accession",
    "resource",
    "archival_object",
    "digital_object",
    "digital_object_component"
  ].each do |object_with_agents|

    # define new link classes for object
    new_class = "#{object_with_agents}_#{dep}_link".classify
    Object.const_set(new_class, Class.new(Sequel::Model("#{object_with_agents}_#{dep}".intern)) {
      many_to_one dep.intern
      many_to_one object_with_agents.intern
    })
  end

end

module Agents

  def self.included(base)
    AgentManager.registered_agents.each do |agent_type|
      link_type = agent_type[:jsonmodel]
      base.one_to_many "#{base.table_name}_#{link_type}_link".intern
    end

    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {})
    obj = super(json, opts)
    self.class.set_agents(json, obj, opts)
    obj
  end


  module ClassMethods

    @@agent_links = AgentManager.type_to_model_map

    def create_from_json(json, opts = {})
      obj = super(json, opts)
      set_agents(json, obj, opts)
      obj
    end


    def set_linked_records(json, obj, opts, json_property, linkable_records)
      linkable_records.keys.each do |link|
        obj.send("#{self.table_name}_#{link}_link_dataset".intern).delete
      end

      (json[json_property] or []).each do |record_link|
        record_type = JSONModel.parse_reference(record_link["ref"], opts)

        model = Kernel.const_get(record_type[:type].camelize)
        record = model[record_type[:id]]

        link = Kernel.const_get("#{self.table_name}_#{record_type[:type]}_link".camelize)

        obj.send("add_#{self.table_name}_#{record_type[:type]}_link".intern,
                 link.create(record_type[:type] => record,
                             self.table_name => obj,
                             :role => record_link["role"]))
      end
    end


    def set_agents(json, obj, opts)
      self.set_linked_records(json, obj, opts, :linked_agents, @@agent_links)
    end


    def sequel_to_jsonmodel(obj, type, opts = {})
      json = super(obj, type)

      [[:linked_agents, @@agent_links]].each do |property, linked_records|
        json[property] = linked_records.keys.map {|record_type|
          obj.send("#{self.table_name}_#{record_type}_link".intern).map {|link|
            {
              "role" => link[:role],
              "ref" => JSONModel(record_type).uri_for(link["#{record_type}_id".intern], opts)
            }
          }
        }.flatten
      end

      json
    end

  end

end
