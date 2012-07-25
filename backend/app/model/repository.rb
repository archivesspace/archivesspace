class Repository < Sequel::Model(:repositories)
  include ASModel

  def create_accession(accession)
    fields = accession.to_hash
    fields = fields.merge(:repo_id => self.repo_id)

    Accession.create(fields)
  end


  def find_accession(accession_id)
    query = {:accession_id => accession_id, :repo_id => self.repo_id}

    Accession[query]
  end

  def all_accessions
    Accession.filter({:repo_id => self.repo_id})
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
