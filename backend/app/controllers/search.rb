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
            ["filter_term", [String], "A json string containing the term/value pairs to be applied to the filter",
             :optional => true],
            ["exclude",
             [String],
             "A list of document IDs that should be excluded from results",
             :optional => true])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:location)]"]) \
  do
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = current_user.username === User.PUBLIC_USERNAME

    query = params[:q] || "*:*"
    query = advanced_query_string(params["aq"].query) if params["aq"]

    json_response(Solr.search(query, params[:page], params[:page_size],
                              params[:repo_id],
                              params[:type], show_suppressed, show_published_only, params[:exclude], params[:filter_term],
                              {
                                "facet.field" => Array(params[:facet]),
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
          ["filter_term", [String], "A json string containing the term/value pairs to be applied to the filter",
           :optional => true],
          ["exclude",
           [String],
           "A list of document IDs that should be excluded from results",
           :optional => true])
    .permissions([:view_all_records])
    .paginated(true)
    .returns([200, ""]) \
  do
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = current_user.username === User.PUBLIC_USERNAME

    query = params[:q] || "*:*"

    query = advanced_query_string(params[:aq]['query']) if params[:aq]

    json_response(Solr.search(query, params[:page], params[:page_size],
                              nil,
                              params[:type], show_suppressed, show_published_only, params[:exclude], params[:filter_term],
                              {
                                "facet.field" => Array(params[:facet]),
                                "sort" => params[:sort]
                              }))
  end


  Endpoint.get('/search/tree_view')
  .description("Find the tree view for a particular archival record")
  .params(["node_uri", String, "The URI of the archival record to find the tree view for"])
  .permissions([:view_all_records])
  .returns([200, "OK"],
           [404, '{"error":"Tree for node_uri not found"}']) \
  do

    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = current_user.username === User.PUBLIC_USERNAME

    node_info = JSONModel.parse_reference(params[:node_uri])

    raise RecordNotFound.new if node_info.nil?

    search_data = Solr.search("*:*", 1, 1,
                              JSONModel(:repository).id_for(node_info[:repository]),
                              nil, show_suppressed, show_published_only, [],
                              [{
                                 :exclude_by_default => true,
                                 :node_uri => params[:node_uri]
                               }.to_json])

    raise RecordNotFound.new if search_data["total_hits"] === 0

    json_response(search_data["results"][0])

  end


  def advanced_query_string(advanced_query)
    if advanced_query.has_key?('subqueries')
      "(#{advanced_query['subqueries'].map{|subq| advanced_query_string(subq)}.join(" #{advanced_query['op']} ")})"
    else
      "#{advanced_query['negated']?"-":""}#{advanced_query['field']}:(#{advanced_query['value']})"
    end
  end

end
