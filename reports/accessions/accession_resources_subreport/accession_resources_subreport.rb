class AccessionResourcesSubreport < AbstractReport

  def template
    "accession_resources_subreport.erb"
  end

  def query
    relationships = db[:spawned_rlshp].
                      filter(:spawned_rlshp__accession_id => @params.fetch(:accessionId))

    db[:resource]
      .filter(:id => relationships.select(:resource_id))
      .select(Sequel.as(:identifier, :identifier),
              Sequel.as(:title, :title))
  end

end
