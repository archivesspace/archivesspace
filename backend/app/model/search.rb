class Search


  def self.search(params, repo_id )
   
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
          highlighting(params[:hl]).
          set_writer_type( params[:dt] || "json" )

      query.remove_csv_header if ( params[:dt] == "csv" and params[:no_csv_header] ) 
    
      Solr.search(query)
  end

  def self.search_csv( params, repo_id )  
    # first let's get a json response with the number of pages 
    p = params.dup
    p[:dt] = "json"
    result = search(p, repo_id)
    
    total_pages = params[:last_page]
    page = 2 # we start on the second page bc the first will have headers

    Enumerator.new do |y|
      y << search(params, repo_id)
      while page != total_pages 
        params[:page] = page
        params[:no_csv_header] = true 
        y << search(params, repo_id)
        page +=1 
      end
    end
  end

end
