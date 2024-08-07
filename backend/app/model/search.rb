require_relative 'search_resolver'

class Search

  def self.search(params, repo_id)
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = RequestContext.get(:current_username) === User.PUBLIC_USERNAME

    Log.debug("backend search received params: #{params.inspect}")

    query = if params[:q]
              Solr::Query.create_keyword_search(params[:q])
            elsif params[:aq] && params[:aq]['query']
              Solr::Query.create_advanced_search(params[:aq], protect_unpublished: show_published_only)
            else
              Solr::Query.create_match_all_query
            end

    query.pagination(params[:page], params[:page_size]).
      set_repo_id(repo_id).
      set_record_types(params[:type]).
      show_suppressed(show_suppressed).
      show_published_only(show_published_only).
      set_excluded_ids(params[:exclude]).
      set_filter(params[:filter]).
      set_filter_queries(params[:filter_query]).
      set_facets(params[:facet], (params[:facet_mincount] || 0)).
      set_sort(params[:sort]).
      set_root_record(params[:root_record]).
      highlighting(params[:hl]).
      set_writer_type( params[:dt] || "json" )

    query.remove_csv_header if ( params[:dt] == "csv" and params[:no_csv_header] )
    query.limit_fields_to(params[:fields]) if params[:fields] && (AppConfig[:limit_csv_fields] || params[:dt] != "csv")

    results = Solr.search(query)

    if params[:resolve]
      # As with the ArchivesSpace API, resolving a field gives a way of
      # returning linked records without having to make multiple queries.
      #
      # In the case of searching, a resolve parameter like:
      #
      #      &resolve[]=repository:id
      #
      # will take the (stored) field value for "repository" and search for
      # that value in the "id" field of other Solr documents.  Any document(s)
      # returned will be inserted into the search response under the key
      # "_resolved_repository".
      #
      # Since you might want to resolve a multi-valued field, we'll use the
      # following format:
      #
      #      "_resolved_myfield": {
      #          "/stored/value/1": [{... matched record 1...}, {... matched record 2...}],
      #          "/stored/value/2": [{... matched record 1...}, {... matched record 2...}]
      #      }
      #
      # To avoid the inlined resolved records being unreasonably large, you can
      # also specify a custom resolver to be used when rendering the record.
      # For example, the query:
      #
      #      &resolve[]=resource:id@compact_resource
      #
      # will use the "compact_resource" resolver to render the inlined resource
      # records.  This is defined by `search_resolver_compact_resource.rb`.  You
      # can define as many of these classes as needed, and they'll be available
      # via the API in this same way.
      resolver = SearchResolver.new(params[:resolve])
      resolver.resolve(results)
    end

    results
  end

  def self.records_for_uris(uris, resolve = [])
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = RequestContext.get(:current_username) === User.PUBLIC_USERNAME

    boolean_query = JSONModel.JSONModel(:boolean_query)
                    .from_hash('op' => 'OR',
                               'subqueries' => uris.map {|uri|
                                 field = uri.end_with?('#pui') ? 'id' : 'uri'
                                 JSONModel.JSONModel(:field_query)
                                   .from_hash('field' => field,
                                              'value' => uri,
                                              'literal' => true)
                                   .to_hash
                               })

    query = Solr::Query.create_advanced_search(JSONModel.JSONModel(:advanced_query).from_hash('query' => boolean_query))

    query.pagination(1, uris.length).
          show_suppressed(show_suppressed).
          show_published_only(show_published_only)

    results = Solr.search(query)

    resolver = SearchResolver.new(resolve)
    resolver.resolve(results)

    # Keep the ordering that we were passed in our list of URIs
    results['results'].sort_by! {|result| uris.index(result['uri'])}

    results
  end

  def self.record_type_counts(record_types, for_repo_uri = nil)
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = RequestContext.get(:current_username) === User.PUBLIC_USERNAME

    result = {}

    repos_of_interest = if for_repo_uri
                          [for_repo_uri]
                        else
                          Repository.filter(:hidden => 0).select(:id).map do |row|
                            repo_id = row[:id]
                            JSONModel.JSONModel(:repository).uri_for(repo_id)
                          end
                        end

    repos_of_interest.each do |repo_uri|
      result[repo_uri] ||= {}

      record_types.each do |record_type|
        boolean_query = JSONModel.JSONModel(:boolean_query)
                        .from_hash('op' => 'AND',
                                   'subqueries' => [
                                     JSONModel.JSONModel(:boolean_query).from_hash('op' => 'OR',
                                                                                   'subqueries' => [
                                                                                     JSONModel.JSONModel(:field_query)
                                                                                     .from_hash('field' => 'used_within_repository',
                                                                                                'value' => repo_uri,
                                                                                                'literal' => true).to_hash,
                                                                                     JSONModel.JSONModel(:field_query)
                                                                                     .from_hash('field' => 'repository',
                                                                                                'value' => repo_uri,
                                                                                                'literal' => true).to_hash
                                                                                   ]),
                                     JSONModel.JSONModel(:field_query)
                                       .from_hash('field' => 'types',
                                                  'value' => record_type,
                                                  'literal' => true).to_hash,
                                     JSONModel.JSONModel(:field_query)
                                       .from_hash('field' => 'published',
                                                  'value' => 'true',
                                                  'literal' => true).to_hash

                                   ])

        query = Solr::Query.create_advanced_search(JSONModel.JSONModel(:advanced_query).from_hash('query' => boolean_query))
        query.pagination(1, 1).
              show_suppressed(show_suppressed).
              show_published_only(show_published_only)

        hits = Solr.search(query)

        result[repo_uri][record_type] = hits['total_hits']
      end
    end

    if for_repo_uri
      # We're just targeting a single repo
      result.values.first
    else
      result
    end
  end

  def self.search_csv( params, repo_id )
    # first let's get a json response with the number of pages
    p = params.dup
    p[:dt] = "json"
    result = search(p, repo_id)
    total_pages = result["last_page"].to_i || 2
    page = 2 # we start on the second page bc the first will have headers

    Enumerator.new do |y|
      # we get page 1 of csv w headers
      y << search(params, repo_id)
      params[:no_csv_header] = true
      while page <= total_pages
        params[:page] = page
        y << search(params, repo_id)
        page +=1
      end
    end
  end

end
