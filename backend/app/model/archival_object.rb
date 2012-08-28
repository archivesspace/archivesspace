class ArchivalObject < Sequel::Model(:archival_objects)
  plugin :validation_helpers
  include ASModel
  include Subjects


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
    obj = super(json, opts)
    apply_subjects(obj, json, opts)
    obj
  end


  def update_from_json(json, opts = {})
    self.class.set_resource(json, opts)
    obj = super(json, opts)
    self.class.apply_subjects(obj, json, {})
    obj
  end


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.subjects = obj.subjects.map {|subject| JSONModel(:subject).uri_for(subject.id)}

    if obj.resource_id
      json.resource = JSONModel(:resource).uri_for(obj.resource_id,
                                                       {:repo_id => obj.repo_id})

      if obj.parent_id
        json.parent = JSONModel(:archival_object).uri_for(obj.parent_id,
                                                          {:repo_id => obj.repo_id})
      end
    end

    json
  end


  def validate
    validates_unique([:resource_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    super
  end


end
