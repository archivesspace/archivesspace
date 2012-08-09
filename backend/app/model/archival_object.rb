class ArchivalObject < Sequel::Model(:archival_objects)
  plugin :validation_helpers
  include ASModel
  include Identifiers

  many_to_many :subjects

  def children
    ArchivalObject.db[:collection_tree].
                   filter(:parent_id => self.id).
                   select(:child_id).map do |child_id|
      ArchivalObject[child_id[:child_id]]
    end
  end


  def self.apply_subjects(ao, json, opts)
    ao.remove_all_subjects

    (json.subjects or []).each do |subject|
      ao.add_subject(Subject[JSONModel(:subject).id_for(subject)])
    end
  end


  def self.set_collection(ao, json, opts)
    parent_id = JSONModel::parse_reference(json.parent, opts)
    collection_id = JSONModel::parse_reference(json.collection, opts)

    if collection_id
      collection = Collection.get_or_die(collection_id[:id])

      collection.link(:parent => parent_id ? parent_id[:id] : nil,
                      :child => ao[:id])
    end
  end


  ## Hook into the JSON model manipulations to set up references to other
  ## records.

  def self.create_from_json(json, opts = {})
    obj = super
    apply_subjects(obj, json, opts)
    set_collection(obj, json, opts)

    obj
  end


  def update_from_json(json)
    obj = super
    self.class.apply_subjects(obj, json, {})
    self.class.set_collection(obj, json, {})

    obj
  end


  def self.to_jsonmodel(obj, type)
    if obj.is_a? Integer
      # An ID.  Get the Sequel row for it.
      obj = get_or_die(obj)
    end

    json = super(obj, type)
    json.subjects = obj.subjects.map {|subject| JSONModel(:subject).uri_for(subject.id)}
    json
  end

end
