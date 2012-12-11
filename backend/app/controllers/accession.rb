class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:accession_id')
    .description("Update an Accession")
    .params(["accession_id", Integer, "The accession ID to update"],
            ["accession", JSONModel(:accession), "The accession data to update", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :updated]) \
  do
    handle_update(Accession, :accession_id, :accession)
  end


  Endpoint.post('/repositories/:repo_id/accessions/:accession_id/suppressed')
    .description("Suppress this record from non-managers")
    .params(["accession_id", Integer, "The accession ID to update"],
            ["suppressed", BooleanParam, "Suppression state"],
            ["repo_id", :repo_id])
    .preconditions(proc { current_user.can?(:manage_repository) })
    .returns([200, :suppressed]) \
  do
    sup_state = Accession.get_or_die(params[:accession_id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:accession_id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/accessions')
    .description("Create an Accession")
    .params(["accession", JSONModel(:accession), "The accession to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :created]) \
  do
    handle_create(Accession, :accession)
  end


  Endpoint.get('/repositories/:repo_id/accessions')
    .description("Get a list of Accessions for a Repository")
    .params(["repo_id", :repo_id],
            *Endpoint.pagination)
    .returns([200, "[(:accession)]"]) \
  do
    handle_listing(Accession,
                   params[:page], params[:page_size],
                   params[:modified_since])
  end


  Endpoint.get('/repositories/:repo_id/accessions/:accession_id')
    .description("Get an Accession by ID")
    .params(["accession_id", Integer, "The accession ID"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .returns([200, "(:accession)"]) \
  do
    json = Accession.to_jsonmodel(params[:accession_id])

    json_response(resolve_references(json.to_hash, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/accessions/:accession_id/tree')
    .description("Get the tree of resources that relate to an Accession")
    .params(["accession_id", Integer, "The accession ID"],
            ["repo_id", :repo_id])
    .returns([200, "(:accession_tree)"]) \
  do
    accession = Accession.get_or_die(params[:accession_id])

    json_response(JSONModel(:accession_tree).from_hash(accession.tree).to_hash)
  end

end
