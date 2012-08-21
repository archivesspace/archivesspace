class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories')
    .description("Create a Repository")
    .params(["repository", JSONModel(:repository), "The repository to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    repo = Repository.create_from_json(params[:repository])
    created_response(repo[:id])
  end


  Endpoint.get('/repositories/:id')
    .description("Get a Repository by ID")
    .params(["id", Integer, "ID of the repository"])
    .returns([200, "(:repository)"],
             [404, '{"error":"Repository not found"}']) \
  do
    Repository.to_jsonmodel(Repository.get_or_die(params[:id]),
                            :repository).to_json
  end


  Endpoint.get('/repositories')
    .description("Get a list of Repositories")
    .returns([200, "[(:repository)]"]) \
  do
    json_response(Repository.collect {|repo|
                    Repository.to_jsonmodel(repo, :repository).to_hash
                  })
  end

end
