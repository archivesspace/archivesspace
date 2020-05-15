class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:id')
    .description("Update an Accession")
    .params(["id", :id],
            ["accession", JSONModel(:accession), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_accession_record])
    .returns([200, :updated]) \
  do
    handle_update(Accession, params[:id], params[:accession])
  end


  Endpoint.post('/repositories/:repo_id/accessions')
    .description("Create an Accession")
    .params(["accession", JSONModel(:accession), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_accession_record])
    .returns([200, :created]) \
  do
    handle_create(Accession, params[:accession])
  end


  Endpoint.get('/repositories/:repo_id/accessions')
    .description("Get a list of Accessions for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:accession)]"]) \
  do
    handle_listing(Accession, params)
  end


  Endpoint.get('/repositories/:repo_id/accessions/:id')
    .description("Get an Accession by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:accession)"]) \
  do
    json = Accession.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/accessions/:id/top_containers')
    .description("Get Top Containers linked to an Accession")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "a list of linked top containers"],
             [404, "Not found"]) \
  do
    accession = Accession.to_jsonmodel(params[:id])
    json_response(accession[:instances].map {|instance|
                  instance['instance_type'] == 'digital_object' ? nil :
                  instance['sub_container']['top_container']
                }.compact)
  end


  Endpoint.delete('/repositories/:repo_id/accessions/:id')
    .description("Delete an Accession")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Accession, params[:id])
  end

end
