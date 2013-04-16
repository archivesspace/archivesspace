module Notes

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    super(json, opts.merge('notes' => JSON(json.notes),
                           'notes_json_schema_version' => json.class.schema_version),
          apply_linked_records)
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
