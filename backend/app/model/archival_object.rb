class ArchivalObject < Sequel::Model(:archival_objects)
  plugin :validation_helpers
  include ASModel
  include Subjects


  def children
    ArchivalObject.filter(:parent_id => self.id)
  end


  def self.set_collection(json, opts)
    opts["collection_id"] = nil
    opts["parent_id"] = nil

    if json.collection
      opts["collection_id"] = JSONModel::parse_reference(json.collection, opts)[:id]

      if json.parent
        opts["parent_id"] = JSONModel::parse_reference(json.parent, opts)[:id]
      end
    end
  end


  def self.create_from_json(json, opts = {})
    set_collection(json, opts)
    obj = super(json, opts)
    apply_subjects(obj, json, opts)
    obj
  end


  def update_from_json(json, opts = {})
    self.class.set_collection(json, opts)
    obj = super(json, opts)
    self.class.apply_subjects(obj, json, {})
    obj
  end


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.subjects = obj.subjects.map {|subject| JSONModel(:subject).uri_for(subject.id)}

    if obj.collection_id
      json.collection = JSONModel(:collection).uri_for(obj.collection_id,
                                                       {:repo_id => obj.repo_id})

      if obj.parent_id
        json.parent = JSONModel(:archival_object).uri_for(obj.parent_id,
                                                          {:repo_id => obj.repo_id})
      end
    end

    json
  end


  def validate
    validates_unique([:collection_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its collection")
    super
  end


end
