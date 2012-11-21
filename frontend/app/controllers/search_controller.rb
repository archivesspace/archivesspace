class SearchController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:do_search]
  before_filter :user_needs_to_be_a_viewer, :only => [:do_search]

  def do_search
    @search_data = {}
  end

end