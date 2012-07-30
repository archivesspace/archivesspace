class Repository < Sequel::Model(:repositories)
  include ASModel

  plugin :validation_helpers

  def validate
    super
    validates_unique(:repo_id, :message=>"Repository Id already in use")
  end


  def create(thing, jsonobject)
    fields = jsonobject.to_hash
    fields = fields.merge(:repo_id => self.repo_id)

    created = thing.create(fields)

    created[:id]
  end


  def create_accession(accession)
    create(Accession, accession)
  end


  def create_collection(collection)
    create(Collection, collection)
  end


  def create_archival_object(ao)
    create(ArchivalObject, ao)
  end


  def find_resource(query)
    query = query.merge({:repo_id => self.repo_id})

    Resource[query]
  end

end
