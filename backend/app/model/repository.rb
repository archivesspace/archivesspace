class Repository < Sequel::Model(:repositories)
  include ASModel

  def create_accession(accession)
    fields = accession.to_hash
    fields = fields.merge(:repo_id => self.repo_id)

    Accession.create(fields)
  end


  def find_accession(id_parts)
    query = Hash[*[:accession_id_0, :accession_id_1, :accession_id_2, :accession_id_3].zip(id_parts + [''] * 3).flatten]
    query = query.merge({:repo_id => self.repo_id})

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
