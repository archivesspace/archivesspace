class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/collection_management')
    .description("Get a list of Collection Management Records for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:collection_management)]"]) \
  do
    handle_listing(CollectionManagement, params)
  end

end
