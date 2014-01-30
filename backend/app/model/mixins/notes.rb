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

      if obj.class.respond_to?(:node_record_type)
        klass = Kernel.const_get(obj.class.node_record_type.camelize)
        # If the object doesn't have a root record, it IS a root record.
        root_id = obj.respond_to?(:root_record_id) ? obj.root_record_id : obj.id

        notes.map { |note|
          if note["jsonmodel_type"] == "note_index"
            note["items"].map { |item|
              referenced_record = klass.filter(:root_record_id => root_id,
                                              :ref_id => item["reference"]).first
              if !referenced_record.nil?
                item["reference_ref"] = {"ref" => referenced_record.uri}
              end
            }
          end
        }
      end

      json.notes = notes

      json
    end

  end

end
