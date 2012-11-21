class SearchController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:all]
  before_filter :user_needs_to_be_a_viewer, :only => [:all]

  def all

  end

end