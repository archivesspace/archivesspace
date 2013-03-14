class CollectionManagementController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index]
  before_filter(:only => [:index]) {|c| user_must_have("view_repository")}

  def index
#    facets = ["subjects", "accession_date_year"]

#    @search_data = Search.for_type(session[:repo_id], "collection_management", search_params.merge({"facet[]" => facets}))

    @search_data = Search.all(session[:repo_id], search_params.merge({'type[]' => 'collection_management'}))

    @search_data
  end

end
