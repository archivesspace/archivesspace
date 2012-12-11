["accession", "resource", "digital_object"].each do |dep|
  require_relative dep
end


class CollectionManagementAccessionLink < Sequel::Model(:collection_management_accession)
  many_to_one :accession
  many_to_one :collection_management
end

class CollectionManagementResourceLink < Sequel::Model(:collection_management_resource)
  many_to_one :resource
  many_to_one :collection_management
end

class CollectionManagementDigitalObjectLink < Sequel::Model(:collection_management_digital_object)
  many_to_one :digital_object
  many_to_one :collection_management
end


class CollectionManagement < Sequel::Model(:collection_management)
  include ASModel

  set_model_scope :repository
  corresponds_to JSONModel(:collection_management)


  def validate
    if self[:processing_total_extent]
      validates_presence([:processing_total_extent_type])
    end
    super
  end

  @@record_links = {
    :accession => Accession,
    :resource => Resource,
    :digital_object => DigitalObject
  }


  @@record_links.keys.each do |link_type|
    one_to_many "collection_management_#{link_type}_link".intern
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
      obj.send("collection_management_#{link}_link_dataset".intern).delete
    end

    (json[json_property] or []).each do |record_link|
      record_type = parse_reference(record_link["ref"], opts)

      model = Kernel.const_get(record_type[:type].camelize)
      record = model[record_type[:id]]

      link = Kernel.const_get("collection_management_#{record_type[:type]}_link".camelize)

      obj.send("add_collection_management_#{record_type[:type]}_link".intern,
               link.create(record_type[:type] => record,
                           :collection_management => obj))
    end

  end


  def self.set_records(json, obj, opts)
    self.set_linked_records(json, obj, opts, :linked_records, @@record_links)
  end

  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    [[:linked_records, @@record_links]].each do |property, linked_records|
      json[property] = linked_records.keys.map {|record_type|
        obj.send("collection_management_#{record_type}_link".intern).map {|link|
          {
            "ref" => uri_for(record_type, link["#{record_type}_id".intern], opts)
          }
        }
      }.flatten
    end

    json
  end


end
