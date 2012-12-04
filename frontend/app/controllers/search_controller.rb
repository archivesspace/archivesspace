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

    respond_to do |format|
      format.json {
        render :json => @search_data
      }
      format.html {
        store_search
      }
    end
  end

  private

  RECENT_SEARCH_LIMIT = 5

  def store_search
    session[:recent_searches] ||= {}
    session[:recent_searches_index] ||= 0

    token = params["search_token"] if params.has_key?("search_token")

    if token.nil?
      session[:recent_searches_index] = session[:recent_searches_index] + 1
      token = session[:recent_searches_index]
    end

    session[:recent_searches][token] = params.clone.merge({ :timestamp => Time.now })

    # expire old searches
    session[:recent_searches].delete_if {|k, v| k < token - RECENT_SEARCH_LIMIT }

    @search_data["search_token"] = token
  end

end