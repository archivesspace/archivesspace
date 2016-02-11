class SiteController < ApplicationController
  def index
    render :file => 'public/index.html', :layout => false
  end

  def bad_request
    render :json => {
      :error => "yikes"
    }, :status => 400
  end
end
