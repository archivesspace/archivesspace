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
        search_params = params_for_backend_search.merge({"facet[]" => facets})
        search_params["type[]"] = "collection_management"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{I18n.t('collection_management._plural').downcase}." )
      }
    end
  end

end
