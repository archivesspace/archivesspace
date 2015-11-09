class SiteController < ApplicationController
  def index
    render :file => 'public/index.html'
  end
end
