module Notes

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    json.notes = nil

    obj = super

    ps = self.class.dataset.where(:id => self.id).prepare(:update, :update_notes, :notes => :$notes)
    ps.call(:notes => notes_blob.to_sequel_blob)

    obj
  end



  module ClassMethods

    def create_from_json(json, opts = {})
      notes_blob = JSON(json.notes)
      json.notes = nil

      obj = super

      ps = self.dataset.where(:id => obj.id).prepare(:update, :update_notes, :notes => :$notes)
      ps.call(:notes => notes_blob.to_sequel_blob)

      obj
    end


    def sequel_to_jsonmodel(obj, opts = {})
      notes = ASUtils.json_parse(DB.deblob(obj.notes) || "[]")
      obj[:notes] = nil
      json = super
      json.notes = notes

      json
    end

  end


end
