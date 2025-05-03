require 'advanced_query_builder'

class SearchController < ApplicationController

  set_access_control "view_repository" => [:do_search, :advanced_search]

  include ExportHelper

  def advanced_search
    criteria = params_for_backend_search

    queries = advanced_search_queries.reject {|field|
      (field["value"].nil? || field["value"] == "") && !field["empty"]
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
        csv_response( uri, Search.build_filters(criteria), "#{t('search_results.title').downcase}." )
      }
    end
  end

  def do_search
    criteria = params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq})

    context_criteria = params["context_filter_term"] ? {"filter_term[]" => params["context_filter_term"]} : {}

    # linker typeaheads should always sort by score
    context_criteria["sort"] = "score desc" if params["linker"]

    @search_data = Search.all(session[:repo_id], criteria, context_criteria)
    @hide_sort_options = params[:hide_sort_options] == "true"
    @hide_csv_download = params[:hide_csv_download] == "true"

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

        filter_terms = Array(criteria['filter_term[]']).map {|t| ASUtils.json_parse(t) rescue {} }
        is_top_container_search = filter_terms.any? {|term| term['primary_type'] == 'top_container'}

        if is_top_container_search
          # Handle Top Container export specifically by generating CSV from JSON
          Rails.logger.debug("Handling Top Container CSV export via JSON generation in SearchController...")
          search_params = criteria
          search_params.delete('dt')
          search_params['page'] = 1
          search_params['page_size'] = AppConfig.has_key?(:max_top_container_results) ? AppConfig[:max_top_container_results] : 10000
          search_params['resolve[]'] = ['container_profile:id', 'container_locations:id', 'collection:id', 'series:id']
          # Explicitly request the fields needed for the CSV in the JSON response
          search_params['fields[]'] = [
            'title',
            'collection_display_string_u_sstr',
            'series_title_u_sstr',
            'type_enum_s',
            'indicator_u_sstr',
            'indicator_u_icusort', # Include both potential indicator fields
            'barcode_u_sstr',
            'container_profile_display_string_u_sstr',
            'location_display_string_u_sstr'
          ]

          json_response = JSONModel::HTTP::get_json(uri, search_params)
          results = json_response['results']
          Rails.logger.debug("Received #{results.length} Top Container results for CSV generation.")

          headers = [
            I18n.t('search.multi.title', :default => 'Title'),
            I18n.t('search.top_container_mgmt.resource_accession', :default => 'Resource/Accession'),
            I18n.t('search.top_container_mgmt.series', :default => 'Series'),
            I18n.t('search.top_container_mgmt.type', :default => 'Type'),
            I18n.t('search.top_container_mgmt.indicator', :default => 'Indicator'),
            I18n.t('search.top_container_mgmt.barcode', :default => 'Barcode'),
            I18n.t('search.top_container_mgmt.container_profile', :default => 'Container Profile'),
            I18n.t('search.top_container_mgmt.location', :default => 'Location')
          ]

          self.response.headers["Content-Type"] = "text/csv"
          self.response.headers["Content-Disposition"] = "attachment; filename=#{t('top_container._plural').downcase}.#{Time.now.to_i}.csv"
          self.response.headers['Last-Modified'] = Time.now.ctime.to_s

          self.response_body = Enumerator.new do |y|
            y << CSV.generate_line(headers)
            results.each do |result|
              begin
                doc_for_extraction = result

                title = doc_for_extraction['title'] || ''
                collection_raw = doc_for_extraction['collection_display_string_u_sstr']
                collection_display = collection_raw.is_a?(Array) ? collection_raw.first : collection_raw || ''
                series_raw = doc_for_extraction['series_title_u_sstr']
                series_display = series_raw.is_a?(Array) ? series_raw.first : series_raw || ''
                type_raw = doc_for_extraction['type_enum_s']
                type = type_raw.is_a?(Array) ? type_raw.first : type_raw || ''

                # Indicator might be single value or array, handle both
                indicator_raw = doc_for_extraction['indicator_u_sstr'] || doc_for_extraction['indicator_u_icusort']
                indicator = indicator_raw.is_a?(Array) ? indicator_raw.first : indicator_raw || ''

                barcode_raw = doc_for_extraction['barcode_u_sstr']
                barcode = barcode_raw.is_a?(Array) ? barcode_raw.first : barcode_raw || ''
                container_profile_raw = doc_for_extraction['container_profile_display_string_u_sstr']
                container_profile = container_profile_raw.is_a?(Array) ? container_profile_raw.first : container_profile_raw || ''
                location_raw = doc_for_extraction['location_display_string_u_sstr']
                current_location_title = location_raw.is_a?(Array) ? location_raw.first : location_raw || ''

                row_data = [
                  title,
                  collection_display,
                  series_display,
                  type,
                  indicator,
                  barcode,
                  container_profile,
                  current_location_title
                ]

                y << CSV.generate_line(row_data)
              rescue => e
                Rails.logger.error("Error processing row for CSV export: #{result.inspect} - Error: #{e.message}")
                Rails.logger.error(e.backtrace.join("\n"))
              end
            end
          end
          Rails.logger.debug("Finished Top Container CSV generation via JSON.")

        # Original logic for context field and other searches
        # The 'context' field (shown as the "Found in" column for text searches) does not actually exist in the backend;
        # it is derived from the 'ancestors' field at runtime. If it shows up in the fields for the CSV download, we
        # need special processing to populate it properly. (See ANW-1509)
        elsif criteria['fields[]']&.include? 'context'
          Rails.logger.debug("Handling CSV export with derived context field...")
          criteria['fields[]'].delete 'context'
          criteria['fields[]'].append *ContextConverter.ancestor_fields
          send_data csv_export_with_context(uri, Search.build_filters(criteria)),
            filename: "#{t('search_results.title').downcase}.#{Time.now.to_i}.csv"
        else
          # the old way (should generally be faster)
          Rails.logger.debug("Handling standard CSV export via csv_response helper...")
          csv_response(uri, Search.build_filters(criteria), "#{t('search_results.title').downcase}.")
        end
      }
    end
  end

end
