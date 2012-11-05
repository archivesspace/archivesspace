require 'securerandom'

class ArchivalObject < Sequel::Model(:archival_object)
  plugin :validation_helpers
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Agents

  set_model_scope :repository


  def before_create
    super
    self.ref_id = SecureRandom.hex if self.ref_id.nil?
  end


  def children
    ArchivalObject.this_repo.filter(:parent_id => self.id)
  end


  def has_children?
    ArchivalObject.filter(:parent_id => self.id).count > 0
  end


  def self.set_resource(json, opts)
    opts["resource_id"] = nil
    opts["parent_id"] = nil

    if json.resource
      opts["resource_id"] = JSONModel::parse_reference(json.resource, opts)[:id]

      if json.parent
        opts["parent_id"] = JSONModel::parse_reference(json.parent, opts)[:id]
      end
    end
  end


  def self.create_from_json(json, opts = {})
    set_resource(json, opts)
    super
  end


  def update_from_json(json, opts = {})
    # don't allow ref_id to be updated
    json.ref_id = self.ref_id

    self.class.set_resource(json, opts)
    super
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    if obj.resource_id
      json.resource = uri_for(:resource, obj.resource_id)

      if obj.parent_id
        json.parent = uri_for(:archival_object, obj.parent_id)
      end
    end

    json
  end


  def validate
    validates_unique([:resource_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    map_validation_to_json_property([:resource_id, :ref_id], :ref_id)
    super
  end


  def self.records_matching(query, max)
    self.this_repo.where(Sequel.like(Sequel.function(:lower, :title),
                                     "#{query}%".downcase)).first(max)
  end

end
