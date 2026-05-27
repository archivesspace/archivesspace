require 'advanced_query_builder'

class ArchivesSpaceService < Sinatra::Base

  BASE_SEARCH_PARAMS =
    [["q", String, "A search query string.  Uses Lucene 4.0 syntax: http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html  Search index structure can be found in solr/schema.xml",
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
     ["facet_mincount",
      Integer,
      "The minimum count for a facet field to be included in the response",
      :optional => true],
     ["filter", JSONModel(:advanced_query), "A json string containing the advanced query to filter by",
      :optional => true],
     ["filter_query", [String], "Search queries to be applied as a filter to the results.",
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
      :optional => true],
    [ "dt",
        String,
        "Format to return (JSON default)",
        :optional => true ],
    ["fields",
        [String],
        "The list of fields to include in the results",
        :optional => true]
  ]


  Endpoint.get_or_post('/repositories/:repo_id/search')
    .description("Search this repository")
    .params(["repo_id", :repo_id],
            *BASE_SEARCH_PARAMS)
    .paged(true)
    .permissions([:view_repository])
    .returns([200, ""]) \
  do
    if params[:dt] && params[:dt] == "csv"
      stream_response(Search.search_csv(params, params[:repo_id]), "text/csv")
    else
      json_response(Search.search(params, params[:repo_id]))
    end
  end


  Endpoint.get_or_post('/search')
    .description("Search this archive")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([:view_all_records])
    .paged(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params, nil))
  end


  Endpoint.get_or_post('/search/repositories')
    .description("Search across repositories")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([])
    .paged(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params.merge(:type => ['repository']), nil))
  end


  Endpoint.get_or_post('/search/records')
    .description("Return a set of records by URI")
    .params(["uri",
             [String],
             "The list of record URIs to fetch"],
            ["resolve",
             [String],
             "The list of result fields to resolve (if any)",
             :optional => true])
    .permissions([:view_all_records])
    .returns([200, "a JSON map of records"]) \
  do
    records = Search.records_for_uris(Array(params[:uri]), Array(params[:resolve]))

    json_response(records)
  end

  Endpoint.get_or_post('/search/record_types_by_repository')
    .description("Return the counts of record types of interest by repository")
    .params(["record_types", [String], "The list of record types to tally"],
            ["repo_uri",
             String,
             "An optional repository URI.  If given, just return counts for the single repository",
             :optional => true])
    .permissions([:view_all_records])
    .returns([200,
              "If repository is given, returns a map like " +
              "{'record_type' => <count>}." +
              "  Otherwise, {'repo_uri' => {'record_type' => <count>}}"]) \
  do
    json_response(Search.record_type_counts(params[:record_types], params[:repo_uri]))
  end

end
