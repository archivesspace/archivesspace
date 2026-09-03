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

# For supressed records there is no tombstone so using system_mtime serves as both
# ASModel.update_suppressed_flag and ASModel.update_publish_flag update it, and a
# suppressed record can't subsequently be updated.
class OAIHiddenRecordDeletion

  attr_reader :sequel_record

  def initialize(sequel_record)
    @sequel_record = sequel_record
  end

  def id
    @sequel_record.class.my_jsonmodel.uri_for(@sequel_record.id,
                                              :repo_id => @sequel_record.repo_id)
  end

  def deleted?
    true
  end

  def updated_at
    @sequel_record.system_mtime
  end

end
