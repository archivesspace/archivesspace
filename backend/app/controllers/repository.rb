class ArchivesSpaceService < Sinatra::Base

  Endpoint
    .method(:post)
    .uri('/repositories')
    .params(["repository", JSONModel(:repository), "The repository to create", :body => true])
    .returns([200, "OK"]) \
  do
    repo = Repository.create_from_json(params[:repository])
    created_response(repo[:id])
  end


  Endpoint
    .method(:get)
    .uri('/repositories/:id')
    .params(["id", Integer, "The repository to fetch"])
    .returns([200, "OK"]) \
  do
    Repository.to_jsonmodel(Repository.get_or_die(params[:id]),
                            :repository).to_json
  end


  Endpoint
    .method(:get)
    .uri('/repositories')
    .returns([200, "A JSON list of repositories"]) \
  do
    result = []

    json_response(Repository.collect {|repo|
                    Repository.to_jsonmodel(repo, :repository).to_hash
                  })
  end

end
