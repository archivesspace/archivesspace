class CollectionManagementController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index]
  before_filter(:only => [:index]) {|c| user_must_have("view_repository")}

  def index
    @search_data = JSONModel(:collection_management).all(:page => 1)
  end

end
