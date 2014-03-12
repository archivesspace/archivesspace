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
          render :partial => "search/listing", :formats => [:html], :handlers => [:erb]
        else
          render :partial => "search/results", :formats => [:html], :handlers => [:erb]
        end
      }
      format.html {
      }
    end
  end

end
