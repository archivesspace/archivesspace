class Accession < Sequel::Model(:accessions)

  def before_create
    self.create_time = Time.now
    self.last_modified = Time.now
  end


  def before_update
    self.last_modified = Time.now
  end

end
