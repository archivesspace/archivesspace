class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:accession_id')
    .params(["accession_id", Integer, "The accession ID to update"],
            ["accession", JSONModel(:accession), "The accession data to update", :body => true],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    acc = Accession.get_or_die(params[:accession_id], params[:repo_id])
    acc.update_from_json(params[:accession])
    json_response({:status => "Updated", :id => acc[:id]})
  end


  Endpoint.post('/repositories/:repo_id/accessions')
    .params(["accession", JSONModel(:accession), "The accession to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    accession = Accession.create_from_json(params[:accession],
                                           :repo_id => params[:repo_id])

    created_response(accession[:id], params[:accession]._warnings)
  end


  Endpoint.get('/repositories/:repo_id/accessions')
    .params(["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    json_response(Accession.filter(:repo_id => params[:repo_id]).collect {|acc|
                    Accession.to_jsonmodel(acc, :accession).to_hash
                  })
  end


  Endpoint.get('/repositories/:repo_id/accessions/:accession_id')
    .params(["accession_id", Integer, "The accession ID"],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    Accession.to_jsonmodel(params[:accession_id], :accession, params[:repo_id]).to_json
  end
end
