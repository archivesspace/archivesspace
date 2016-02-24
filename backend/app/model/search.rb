class Search


  def self.search(params, repo_id)
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = RequestContext.get(:current_username) === User.PUBLIC_USERNAME

    Log.debug(params.inspect)

    query = if params[:q]
              Solr::Query.create_keyword_search(params[:q])
            elsif params[:aq] && params[:aq]['query']
              Solr::Query.create_advanced_search(params[:aq])
            else
              Solr::Query.create_match_all_query
            end


    query.pagination(params[:page], params[:page_size]).
          set_repo_id(repo_id).
          set_record_types(params[:type]).
          show_suppressed(show_suppressed).
          show_published_only(show_published_only).
          set_excluded_ids(params[:exclude]).
          set_filter_terms(params[:filter_term]).
          set_simple_filters(params[:simple_filter]).
          set_facets(params[:facet]).
          set_sort(params[:sort]).
          set_root_record(params[:root_record]).
          highlighting(params[:hl])


    Solr.search(query)
  end

end
