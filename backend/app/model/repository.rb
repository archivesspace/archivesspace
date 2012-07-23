class Repository < Sequel::Model(:repositories)
  include ASModel

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
