class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/resources/:id/small_tree')
  .description("Search for top containers")
  .params(["repo_id", :repo_id],
          ["id", :id])
  .permissions([:view_repository])
  .returns([200, ""]) \
  do
    json_response(SmallTree.for_resource(params[:id]))
  end

end
