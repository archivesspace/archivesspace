module Notes

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json,
          opts.merge('notes' => JSON(json.notes),
                     'notes_json_schema_version' => json.class.schema_version),
          apply_nested_records)
  end


  def publish!
    updated_notes = ASUtils.json_parse(self.notes || "[]")
    if not updated_notes.empty?
      updated_notes.each do |note|
        note["publish"] = true
      end

      self.notes = JSON(updated_notes)
    end

    super
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      super(json, opts.merge('notes' => JSON(json.notes),
                             'notes_json_schema_version' => json.class.schema_version))
    end


    def sequel_to_jsonmodel(obj, opts = {})
      notes = ASUtils.json_parse(obj.notes || "[]")
      obj[:notes] = nil
      json = super
      json.notes = notes

      json
    end

  end

end
