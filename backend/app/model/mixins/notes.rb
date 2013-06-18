module Notes

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    self.class.apply_notes(json, proc { |json, opts|
                             super(json, opts, apply_linked_records)
                           }, opts)
  end


  def publish!
    notes = ASUtils.json_parse(self.notes || "[]")
    if not notes.empty?
      notes.each do |note|
        note["publish"] = true
      end
      self.notes = JSON(notes)
    end

    super
  end

  module ClassMethods

    def create_from_json(json, opts = {})
      self.apply_notes(json, proc { |json, opts|
                         super(json, opts)
                       }, opts)
    end


    def apply_notes(json, super_callback, opts)
      notes_blob = JSON(json.notes)

      if notes_blob.length >= 8000
        # We need to use prepared statement to store the notes blob once it gets
        # large.  This is because Sequel uses string literals and some databases
        # have an upper limit on how long they're allowed to be.

        obj = super_callback.call(json, opts.merge('notes' => nil,
                                                   'notes_json_schema_version' => json.class.schema_version))

        ps = self.dataset.where(:id => obj.id).prepare(:update, :update_notes, :notes => :$notes)
        ps.call(:notes => DB.blobify(notes_blob))

        obj
      else
        # Use the standard method for saving the notes (and avoid the extra update)
        super_callback.call(json, opts.merge('notes' => notes_blob,
                                             'notes_json_schema_version' => json.class.schema_version))
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
