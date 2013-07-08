class SearchController < ApplicationController

  set_access_control  "view_repository" => :do_search


  def do_search
    @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))

    respond_to do |format|
      format.json {
        render :json => @search_data
      }
      format.js {
        if params[:listing_only]
          render :partial => "search/listing"
        else
          render :partial => "search/results"
        end
      }
      format.html {
        store_search
      }
    end
  end

  private

  RECENT_SEARCH_LIMIT = 5

  def store_search
    session[:recent_searches] ||= {}
    session[:recent_searches_index] ||= 0

    token = params["search_token"] if params.has_key?("search_token")

    if token.nil?
      session[:recent_searches_index] = session[:recent_searches_index] + 1
      token = session[:recent_searches_index]
    end

    session[:recent_searches][token] = params.clone.merge({ :timestamp => Time.now })

    # expire old searches
    session[:recent_searches].delete_if {|k, v| k < token - RECENT_SEARCH_LIMIT }

    @search_data["search_token"] = token
  end

end
