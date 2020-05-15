require 'advanced_query_builder'

class SearchController < ApplicationController
  # This class provides search functionality through the frontend.  Methods
  # here generally perform a search against the backend, then render those search results
  # as JSON or HTML fragments to be rendered into tables in the application,
  # either directly in templates, or as responses to ajax calls.

  set_access_control  "view_repository" => [:do_search, :advanced_search]

  include ExportHelper

  def advanced_search
    @display_context = true

    criteria = params_for_backend_search

    queries = advanced_search_queries

    queries = queries.reject{|field|
      if field['type'] === 'range'
        field['from'].nil? && field['to'].nil?
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
    # Execute a backend search, rendering results as JSON/HTML fragment/HTML/CSS
    #
    # In addition to params handled by ApplicationController#params_for_backend_search, takes:
    #   :extra_columns - hash with keys 'title', 'field', 'sort_options' (hash with keys 'sortable', 'sort_by')
    #   :display_identifier - whether to display the identifier column
    #   :hide_audit_info - whether to display the updated/changed timestamps
    #   :show_context_column - whether to display the context column
    #
    #
    # 'title' in extra_columns will try to use the string as a translation key,
    #  and fall back to the raw string if there's no translation.
    #
    # For example to add uri to the data-browse field of an AJAX-backed table:
    #
    #    data-browse-url="<%= url_for :controller => :search, :action => :do_search,
    #                                 :extra_columns => [{
    #                                    'title' => 'uri',
    #                                    'formatter' =>'stringify',
    #                                    'field'=> 'uri',
    #                                    'sort_options' => {'sortable' => true, 'sort_by' => 'uri'}
    #                                  }],
    #                                  :format => :json, :facets => [], :sort => "title_sort asc" %>"
    #
    # The date-browse-url field would be identical, but with :format => :js
    #
    # Note: you will need to add an entry to frontend/config/locales under the search_sorting key for the title of any column you add

    unless request.format.csv?
      @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))
      if params[:extra_columns]
        @extra_columns = params[:extra_columns].map do |opts|
          SearchHelper::ExtraColumn.new(I18n.t(opts['title'], default: opts['title']), SearchHelper::Formatter[opts['formatter'], opts['field']], opts['sort_options'] || {}, @search_data)
        end
      end
      @display_identifier = params.fetch(:display_identifier, false) == 'true'
      @hide_audit_info = params.fetch(:hide_audit_info, false) == 'true'
      @display_context = params.fetch(:show_context_column, false) == 'true'
    end

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

    @display_context = true

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
        # default render
      }
      format.csv { 
        criteria = params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS})
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(criteria), 'search_results.' )
      }  
    end
  end


end
