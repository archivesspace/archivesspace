class DigitalObject < Sequel::Model(:digital_object)
  plugin :validation_helpers
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Trees

  tree_of(:digital_object, :digital_object_component)
  set_model_scope :repository

  def link(opts)
    child = DigitalObjectComponent.get_or_die(opts[:child])
    child.digital_object_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end


  def self.create_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    json.notes = nil
    super(json, opts.merge(:notes => notes_blob))
  end


  def update_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    json.notes = nil
    super(json, opts.merge(:notes => notes_blob))
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    notes = JSON.parse(obj.notes || "[]")
    obj[:notes] = nil
    json = super
    json.notes = notes

    json
  end

end
