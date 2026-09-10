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

# For suppressed and unpublished records there is no tombstone, so hidden_at
# stands records when the record became unavailable and is not updated until
# the records becomes available again. Records hidden by something other than
# their own flags - an unpublished ancestor - have no hidden_at, and fall back
# to system_mtime.
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
    @sequel_record[:hidden_at] || @sequel_record.system_mtime
  end
end
