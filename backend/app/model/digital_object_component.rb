class DigitalObjectComponent < Sequel::Model(:digital_object_component)
  plugin :validation_helpers
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents

  set_model_scope :repository

  def children
    repository_view.filter(:parent_id => self.id)
  end


  def self.set_digital_object(json, opts)
    opts["digital_object_id"] = nil
    opts["parent_id"] = nil

    if json.digital_object
      opts["digital_object_id"] = JSONModel::parse_reference(json.digital_object, opts)[:id]

      if json.parent
        opts["parent_id"] = JSONModel::parse_reference(json.parent, opts)[:id]
      end
    end
  end


  def self.create_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    json.notes = nil
    self.set_digital_object(json, opts)
    super(json, opts.merge(:notes => notes_blob))
  end


  def update_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    self.class.set_digital_object(json, opts)
    json.notes = nil
    super(json, opts.merge(:notes => notes_blob))
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    notes = JSON.parse(obj.notes || "[]")
    obj[:notes] = nil
    json = super
    json.notes = notes

    if obj.digital_object_id
      json.digital_object = JSONModel(:digital_object).uri_for(obj.digital_object_id,
                                                               :repo_id => obj.repo_id)

      if obj.parent_id
        json.parent = JSONModel(:digital_object_component).uri_for(obj.parent_id,
                                                                   :repo_id => obj.repo_id)
      end
    end

    json
  end

end
