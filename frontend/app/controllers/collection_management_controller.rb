class CollectionManagementController < ApplicationController

  set_access_control  "view_repository" => [:index]


  def index
    facets = ["parent_type", "processing_priority", "processing_status"]

    @search_data = Search.for_type(session[:repo_id], "collection_management", search_params.merge({"facet[]" => facets}))
  end

end
