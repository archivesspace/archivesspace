module Notes

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    self.class.apply_notes(json.notes, proc { |opts|
                             super(json, opts, apply_linked_records)
                           },
                           opts.merge('notes_json_schema_version' => json.class.schema_version))
  end


  def publish!
    updated_notes = ASUtils.json_parse(self.notes || "[]")
    if not updated_notes.empty?
      updated_notes.each do |note|
        note["publish"] = true
      end
    end

    self.class.apply_notes(updated_notes, proc { |opts|
                             old_notes = self.notes
                             self.notes = opts['notes']
                             result = super
                             self.notes = old_notes

                             result
                           },
                           {})
  end

  module ClassMethods

    def create_from_json(json, opts = {})
      self.apply_notes(json.notes, proc { |opts|
                         super(json, opts)
                       },
                       opts.merge('notes_json_schema_version' => json.class.schema_version))
    end


    def apply_notes(notes, super_callback, opts)
      notes_blob = JSON(notes)

      if notes_blob.length >= 8000
        # We need to use prepared statement to store the notes blob once it gets
        # large.  This is because Sequel uses string literals and some databases
        # have an upper limit on how long they're allowed to be.

        obj = super_callback.call(opts.merge('notes' => nil))

        ps = self.dataset.where(:id => obj.id).prepare(:update, :update_notes, :notes => :$notes)
        ps.call(:notes => DB.blobify(notes_blob))

        obj
      else
        # Use the standard method for saving the notes (and avoid the extra update)
        super_callback.call(opts.merge('notes' => notes_blob))
      end
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
