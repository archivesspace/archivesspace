module Notes

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    super(json, opts.merge('notes' => JSON(json.notes)), apply_linked_records)
  end



  module ClassMethods

    def create_from_json(json, opts = {})
      super(json, opts.merge('notes' => JSON(json.notes)))
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
