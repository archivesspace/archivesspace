class Repository < Sequel::Model(:repositories)

  def before_create
    self.create_time = Time.now
    self.last_modified = Time.now
  end


  def before_update
    self.last_modified = Time.now
  end


  def create_accession(opts)
    fields = opts.merge(:repo_id => self.repo_id)

    Accession.create(fields)
  end


  def find_accession(query)
    query = query.merge({:repo_id => self.repo_id})

    Accession[query]
  end


  def create_resource(opts)
    fields = opts.merge(:repo_id => self.repo_id)

    Resource.create(fields)
  end


  def find_resource(query)
    query = query.merge({:repo_id => self.repo_id})

    Resource[query]
  end

end
