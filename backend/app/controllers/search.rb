class ArchivesSpaceService < Sinatra::Base

  BASE_SEARCH_PARAMS =
    [["q", String, "A search query string",
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
     ["filter_term", [String], "A json string containing the term/value pairs to be applied as filters.  Of the form: {\"fieldname\": \"fieldvalue\"}.",
      :optional => true],
     ["simple_filter", [String], "A simple direct filter to be applied as a filter. Of the form 'primary_type:accession OR primary_type:agent_person'.",
      :optional => true],
      ["exclude",
      [String],
      "A list of document IDs that should be excluded from results",
      :optional => true],
      ["hl",
      BooleanParam,
      "Whether to use highlighting",
      :optional => true],
     ["root_record",
      String,
      "Search within a collection of records (defined by the record at the root of the tree)",
      :optional => true]]


  Endpoint.get('/repositories/:repo_id/search')
    .description("Search this repository")
    .params(["repo_id", :repo_id],
            *BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, ""]) \
  do
    json_response(Search.search(params, params[:repo_id]))
  end


  Endpoint.get('/search')
    .description("Search this archive")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([:view_all_records])
    .paginated(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params, nil))
  end


  Endpoint.get('/search/repositories')
    .description("Search across repositories")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([])
    .paginated(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params.merge(:type => ['repository']), nil))
  end


  Endpoint.get('/search/subjects')
    .description("Search across subjects")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([])
    .paginated(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params.merge(:type => ['subject']), nil))
  end


  Endpoint.get('/search/published_tree')
  .description("Find the tree view for a particular archival record")
  .params(["node_uri", String, "The URI of the archival record to find the tree view for"])
  .permissions([:view_all_records])
  .returns([200, "OK"],
           [404, "Not found"]) \
  do

    show_suppressed = !RequestContext.get(:enforce_suppression)

    node_info = JSONModel.parse_reference(params[:node_uri])

    raise RecordNotFound.new if node_info.nil?

    query = Solr::Query.create_match_all_query.
                        pagination(1, 1).
                        set_repo_id(JSONModel(:repository).id_for(node_info[:repository])).
                        set_record_types(['tree_view']).
                        show_suppressed(show_suppressed).
                        show_excluded_docs(true).
                        set_filter_terms([
                                          {
                                            :node_uri => params[:node_uri]
                                          }.to_json
                                         ])

    search_data = Solr.search(query)

    raise RecordNotFound.new if search_data["total_hits"] === 0

    json_response(search_data["results"][0])
  end

end
