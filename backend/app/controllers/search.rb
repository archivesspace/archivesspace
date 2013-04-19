class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/search')
    .description("Search this repository")
    .params(["repo_id", :repo_id],
            ["q", String, "A search query string",
             :optional => true],
            ["aq", JSONModel(:advanced_query), "A json string containing the advanced query",
             :optional => true],
            ["type",
             [String],
             "The record type to search (defaults to all types if not specified)",
             :optional => true],
            ["sort",
             String,
             "The attribute to sort and the direction e.g. &sort=title desc&...",
             :optional => true],
            ["facet",
             [String],
             "The list of the fields to produce facets for",
             :optional => true],
            ["filter",
             [String],
             "The list of the facets to filter on",
             :optional => true],
            ["exclude",
             [String],
             "A list of document IDs that should be excluded from results",
             :optional => true],
            *Endpoint.pagination)
    .permissions([:view_repository])
    .returns([200, "[(:location)]"]) \
  do
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = current_user.username === User.SEARCH_USERNAME

    query = params[:q] || "*:*"

    query = advanced_query_string(params["aq"].query) if params["aq"]

    json_response(Solr.search(query, params[:page], params[:page_size],
                              params[:repo_id],
                              params[:type], show_suppressed, show_published_only, params[:exclude],
                              {
                                "facet.field" => Array(params[:facet]),
                                "fq" => Array(params[:filter]),
                                "sort" => params[:sort]
                              }))
  end

  Endpoint.get('/search')
  .description("Search this archive")
  .params(["q", String, "A search query string",
           :optional => true],
          ["aq", JSONModel(:advanced_query), "A json string containing the advanced query",
           :optional => true],
          ["type",
           [String],
           "The record type to search (defaults to all types if not specified)",
           :optional => true],
          ["sort",
           String,
           "The attribute to sort and the direction e.g. &sort=title desc&...",
           :optional => true],
          ["facet",
           [String],
           "The list of the fields to produce facets for",
           :optional => true],
          ["filter",
           [String],
           "The list of the facets to filter on",
           :optional => true],
          ["exclude",
           [String],
           "A list of document IDs that should be excluded from results",
           :optional => true],
          *Endpoint.pagination)
  .nopermissionsyet
  .returns([200, "[(:location)]"]) \
  do
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = current_user.username === User.SEARCH_USERNAME

    query = params[:q] || "*:*"

    query = advanced_query_string(params[:aq]['query']) if params[:aq]

    json_response(Solr.search(query, params[:page], params[:page_size],
                              nil,
                              params[:type], show_suppressed, show_published_only, params[:exclude],
                              {
                                "facet.field" => Array(params[:facet]),
                                "fq" => Array(params[:filter]),
                                "sort" => params[:sort]
                              }))
  end

  def advanced_query_string(advanced_query)
    if advanced_query.has_key?('subqueries')
      "(#{advanced_query['subqueries'].map{|subq| advanced_query_string(subq)}.join(" #{advanced_query['op']} ")})"
    else
      "#{advanced_query['negated']?"-":""}#{advanced_query['field']}:(#{advanced_query['value']})"
    end
  end

end
