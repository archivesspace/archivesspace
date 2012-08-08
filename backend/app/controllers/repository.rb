class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories')
    .params(["repository", JSONModel(:repository), "The repository to create", :body => true])
    .returns([200, "OK"]) \
  do
    repo = Repository.create_from_json(params[:repository])
    created_response(repo[:id])
  end


  Endpoint.get('/repositories/:id')
    .params(["id", Integer, "The repository to fetch"])
    .returns([200, "OK"]) \
  do
    Repository.to_jsonmodel(Repository.get_or_die(params[:id]),
                            :repository).to_json
  end


  Endpoint.get('/repositories')
    .returns([200, "A JSON list of repositories"]) \
  do
    json_response(Repository.collect {|repo|
                    Repository.to_jsonmodel(repo, :repository).to_hash
                  })
  end

end
