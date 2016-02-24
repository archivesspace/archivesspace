class SiteController < ApplicationController
  def index

  end

  def bad_request
    render :json => {
      :error => "yikes"
    }, :status => 400
  end
end
