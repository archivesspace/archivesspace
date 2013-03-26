class CollectionManagementController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index]
  before_filter(:only => [:index]) {|c| user_must_have("view_repository")}

  def index
    facets = ["parent_type", "processing_priority", "processing_status"]

    @search_data = Search.for_type(session[:repo_id], "collection_management", search_params.merge({"facet[]" => facets}))
  end

end
