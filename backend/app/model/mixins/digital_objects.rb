module DigitalObjects

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super
    reindex_linked_records
    result
  end

  def reindex_linked_records
    self.class.update_mtime_for_ids([self.id])
  end

end
