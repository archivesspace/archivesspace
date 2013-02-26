class SearchController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:do_search]
  before_filter(:only => [:do_search]) {|c| user_must_have("view_repository")}

  def do_search
    @search_data = Search.all(session[:repo_id], search_params.merge({"facet[]" => ["primary_type","creators","subjects"]}))

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
