require 'advanced_query_builder'

class SearchController < ApplicationController

  set_access_control  "view_repository" => [:do_search, :advanced_search]
  
  include ExportHelper

  def advanced_search
    criteria = params_for_backend_search

    queries = advanced_search_queries.reject{|field|
      (field["value"].nil? || field["value"] == "") && !field["empty"]
    }

    if not queries.empty?
      criteria["aq"] = AdvancedQueryBuilder.build_query_from_form(queries).to_json
      criteria['facet[]'] = SearchResultData.BASE_FACETS
    end



    respond_to do |format|
      format.json {
        @search_data = Search.all(session[:repo_id], criteria)
        render :json => @search_data
      }
      format.js {
        @search_data = Search.all(session[:repo_id], criteria)
        if params[:listing_only]
          render_aspace_partial :partial => "search/listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
        @search_data = Search.all(session[:repo_id], criteria)
        render "search/do_search"
      }
      format.csv { 
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, criteria )
      }  
    end
  end

  def do_search

    respond_to do |format|
      format.json {
        @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))
        @display_identifier = params[:display_identifier] ? params[:display_identifier] : false
        render :json => @search_data
      }
      format.js {
        @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))
        @display_identifier = params[:display_identifier] ? params[:display_identifier] : false
        if params[:listing_only]
          render_aspace_partial :partial => "search/listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
        @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))
        @display_identifier = params[:display_identifier] ? params[:display_identifier] : false
      }
      format.csv { 
        criteria = params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS})
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, criteria )
      }  
    end
  end

end
