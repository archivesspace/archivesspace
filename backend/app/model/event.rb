["accession", "resource", "archival_object"].each do |dep|
  require_relative dep
end


class EventAccessionLink < Sequel::Model(:event_accession)
  many_to_one :accession
  many_to_one :event
end

class EventResourceLink < Sequel::Model(:event_resource)
  many_to_one :resource
  many_to_one :event
end

class EventArchivalObjectLink < Sequel::Model(:event_archival_object)
  many_to_one :archival_object
  many_to_one :event
end



class Event < Sequel::Model(:event)
  plugin :validation_helpers

  include ASModel
  Sequel.extension :inflector

  include Agents

  set_model_scope :repository

  one_to_many :date, :class => "ASDate"
  jsonmodel_hint(:the_property => :date,
                 :contains_records_of_type => :date,
                 :corresponding_to_association => :date,
                 :is_array => false,
                 :always_resolve => true)

  @@record_links = {
    :accession => Accession,
    :resource => Resource,
    :archival_object => ArchivalObject
  }


  @@record_links.keys.each do |link_type|
    one_to_many "event_#{link_type}_link".intern
  end


  def self.linkable_records_for(prefix)
    @@record_links.map {|record_type, record_model|
      [record_type, record_model.records_matching(prefix, 10)]
    }
  end



  def self.create_from_json(json, opts = {})
    obj = super
    set_records(json, obj, opts)
    obj
  end


  def update_from_json(json, opts = {})
    obj = super
    self.class.set_records(json, obj, opts)
    obj
  end


  def self.set_linked_records(json, obj, opts, json_property, linkable_records)
    linkable_records.keys.each do |link|
      obj.send("event_#{link}_link_dataset".intern).delete
    end

    (json[json_property] or []).each do |record_link|
      record_type = JSONModel.parse_reference(record_link["ref"], opts)

      model = Kernel.const_get(record_type[:type].camelize)
      record = model[record_type[:id]]

      link = Kernel.const_get("event_#{record_type[:type]}_link".camelize)

      obj.send("add_event_#{record_type[:type]}_link".intern,
               link.create(record_type[:type] => record,
                           :event => obj,
                           :role => record_link["role"]))
    end

  end


  def self.set_records(json, obj, opts)
    self.set_linked_records(json, obj, opts, :linked_records, @@record_links)
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    [[:linked_records, @@record_links]].each do |property, linked_records|
      json[property] = linked_records.keys.map {|record_type|
        obj.send("event_#{record_type}_link".intern).map {|link|
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
