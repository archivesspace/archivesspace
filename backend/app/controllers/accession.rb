class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:accession_id')
    .description("Update an Accession")
    .params(["accession_id", Integer, "The accession ID to update"],
            ["accession", JSONModel(:accession), "The accession data to update", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :updated]) \
  do
    acc = Accession.get_or_die(params[:accession_id], params[:repo_id])
    acc.update_from_json(params[:accession])
    updated_response(acc, params[:accession])
  end


  Endpoint.post('/repositories/:repo_id/accessions')
    .description("Create an Accession")
    .params(["accession", JSONModel(:accession), "The accession to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :created]) \
  do
    accession = Accession.create_from_json(params[:accession],
                                           :repo_id => params[:repo_id])

    created_response(accession, params[:accession])
  end


  Endpoint.get('/repositories/:repo_id/accessions')
    .description("Get a list of Accessions for a Repository")
    .params(["repo_id", :repo_id])
    .returns([200, "[(:accession)]"]) \
  do
    json_response(Accession.filter(:repo_id => params[:repo_id]).collect {|acc|
                    Accession.to_jsonmodel(acc, :accession).to_hash
                  })
  end


  Endpoint.get('/repositories/:repo_id/accessions/:accession_id')
    .description("Get an Accession by ID")
    .params(["accession_id", Integer, "The accession ID"],
            ["repo_id", :repo_id])
    .returns([200, "(:accession)"]) \
  do
    Accession.to_jsonmodel(params[:accession_id], :accession, params[:repo_id]).to_json
  end
end
