class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories')
    .description("Create a Repository")
    .params(["repository", JSONModel(:repository), "The repository to create", :body => true])
    .preconditions(proc { current_user.can?(:create_repository) })
    .returns([200, :created],
             [400, :error],
             [403, :access_denied]) \
  do
    handle_create(Repository, :repository)
  end


  Endpoint.get('/repositories/:id')
    .description("Get a Repository by ID")
    .params(["id", Integer, "ID of the repository"])
    .returns([200, "(:repository)"],
             [404, '{"error":"Repository not found"}']) \
  do
    json_response(Repository.to_jsonmodel(Repository.get_or_die(params[:id]),
                                          :repository,
                                          :none))
  end


  Endpoint.get('/repositories')
    .description("Get a list of Repositories")
    .returns([200, "[(:repository)]"]) \
  do
    handle_listing(Repository, :repository,
                   :hidden => 0)
  end

end
