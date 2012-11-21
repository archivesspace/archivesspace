class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/search')
    .description("Search this repository")
    .params(["repo_id", :repo_id],
            ["q", String, "A search query string"],
            ["type",
             String,
             "The record type to search (defaults to all types if not specified)",
             :optional => true],
            *Endpoint.pagination)
    .returns([200, "[(:location)]"]) \
  do
    json_response(Solr.search(params[:q], params[:type]))
  end

end
