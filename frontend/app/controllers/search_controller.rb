require 'advanced_query_builder'

class SearchController < ApplicationController

  set_access_control  "view_repository" => [:do_search, :advanced_search]
  
  include ExportHelper

  def advanced_search
    @display_context = true

    criteria = params_for_backend_search

    queries = advanced_search_queries

    queries = queries.reject{|field|
      if field['type'] === 'range'
        field['from'].nil? && field['to'].nil?
      elsif field['type'] === 'series_system'
        false
      else
        (field["value"].nil? || field["value"] == "") && !field["empty"]
      end
    }

    if not queries.empty?
      if criteria['aq']
        existing_filter = ASUtils.json_parse(criteria['aq'])
        criteria['aq'] =  JSONModel::JSONModel(:advanced_query).from_hash({
                              query: JSONModel(:boolean_query)
                                       .from_hash({
                                                    :jsonmodel_type => 'boolean_query',
                                                    :op => 'AND',
                                                    :subqueries => [existing_filter['query'], AdvancedQueryBuilder.build_query_from_form(queries)['query']]
                                                  })
                            }).to_json
      else
        criteria["aq"] = AdvancedQueryBuilder.build_query_from_form(queries).to_json
      end
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
        csv_response( uri, Search.build_filters(criteria), 'search_results.' )
      }  
    end
  end

  def do_search
    @display_context = true

    if params[:q] && params[:q].end_with?("*")
      # Typeahead search from a linker using wildcards.  These interact badly
      # with stemming because the wildcard causes query analysis to be skipped,
      # so stemming isn't applied to the query.
      #
      # This manifests in real data when you typeahead for "agency*" and get no
      # matches.  That term is stemmed to "agenc".
      #
      # Try to minimise the weird effects of this by searching for the
      # non-wildcard version as well.  The real solution here is to stop using
      # wildcards and use an ngram field instead.
      q = params[:q]

      params[:q] = "(#{q}) OR (#{q.gsub('*', '')})"
    end

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
        criteria = params_for_backend_search
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(criteria), 'search_results.' )
      }  
    end
  end

end
