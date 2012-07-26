class Repository < Sequel::Model(:repositories)
  include ASModel
  
  plugin :validation_helpers
  
  def validate
    super
    validates_unique(:repo_id, :message=>"Repository Id already in use")
  end

  def create_accession(accession)
    fields = accession.to_hash
    fields = fields.merge(:repo_id => self.repo_id)

    created = Accession.create(fields)

    created[:id]
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
