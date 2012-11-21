class SearchController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:do_search]
  before_filter :user_needs_to_be_a_viewer, :only => [:do_search]

  def do_search
    @criteria = {
      :q => params[:q],
      :page => params[:page] || 1
    }
    @criteria[:type] = params[:type] if not params[:type].blank?

    @search_data = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/search", @criteria)
  end

end