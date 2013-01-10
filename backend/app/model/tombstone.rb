class Tombstone < Sequel::Model(:deleted_records)

  def before_save
    self.timestamp = Time.now
    self.operator = RequestContext.get(:current_username)
  end

end
