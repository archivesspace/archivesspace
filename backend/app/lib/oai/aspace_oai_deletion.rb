class OAIDeletion

  def initialize(tombstone)
    @tombstone = tombstone
  end

  def id
    @tombstone.uri
  end

  def tombstone_id
    @tombstone.id
  end

  def deleted?
    true
  end

  def updated_at
    @tombstone.timestamp
  end

end
