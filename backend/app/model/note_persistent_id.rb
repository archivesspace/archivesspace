class NotePersistentId < Sequel::Model(:note_persistent_id)
  def _save_refresh
    # Not needed
  end
end
