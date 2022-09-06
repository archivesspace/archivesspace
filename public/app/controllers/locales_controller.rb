class LocalesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def locale
    session[:locale] = params[:locale]

    redirect_to('/')
  end
end
