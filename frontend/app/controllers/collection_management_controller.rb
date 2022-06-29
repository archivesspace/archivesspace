class CollectionManagementController < ApplicationController

  include ExportHelper

  set_access_control "view_repository" => [:index]


  def index
    facets = ["parent_type", "processing_priority", "processing_status"]

    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "collection_management", params_for_backend_search.merge({"facet[]" => facets}))
      }
      format.csv {
        search_data_csv = Search.for_type(session[:repo_id], "collection_management", params_for_backend_search.merge({"facet[]" => facets, "page_size" => "2147483647"}))
        csv_response_from_search_result_data(search_data_csv, "#{I18n.t('search.collection_management.name').downcase}.")
      }
    end
  end

end
