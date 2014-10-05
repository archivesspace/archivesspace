require 'advanced_query_builder'

class SearchController < ApplicationController

  set_access_control  "view_repository" => [:do_search, :advanced_search]

  def advanced_search
    criteria = params_for_backend_search

    queries = advanced_search_queries.reject{|field| field["value"].nil? || field["value"] == ""}

    if not queries.empty?
      criteria["aq"] = AdvancedQueryBuilder.new(queries, :staff).build_query.to_json
      criteria['facet[]'] = SearchResultData.BASE_FACETS
    end


    @search_data = Search.all(session[:repo_id], criteria)

    respond_to do |format|
      format.json {
        render :json => @search_data
      }
      format.js {
        if params[:listing_only]
          render_aspace_partial :partial => "search/listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
        render "search/do_search"
      }
    end
  end

  def do_search
    @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))

    respond_to do |format|
      format.json {
        render :json => @search_data
      }
      format.js {
        if params[:listing_only]
          render_aspace_partial :partial => "search/listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
      }
    end
  end

end
