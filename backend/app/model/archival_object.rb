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


  def children
    ArchivalObject.filter(:parent_id => self.id)
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
    self.class.set_resource(json, opts)
    super
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    if obj.resource_id
      json.resource = JSONModel(:resource).uri_for(obj.resource_id,
                                                   :repo_id => obj.repo_id)

      if obj.parent_id
        json.parent = JSONModel(:archival_object).uri_for(obj.parent_id,
                                                          :repo_id => obj.repo_id)
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
    self.where(Sequel.like(Sequel.function(:lower, :title),
                           "#{query}%".downcase)).first(max)
  end

end
