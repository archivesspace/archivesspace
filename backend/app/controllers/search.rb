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
    show_suppressed = !RequestContext.get(:enforce_suppression)

    json_response(Solr.search(params[:q], params[:page], params[:page_size],
                              params[:type], show_suppressed))
  end

end
