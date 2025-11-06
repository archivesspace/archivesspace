class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    render 'shared/login'
  end

  def login
    uri = "/users/#{params[:user_name]}/login"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    response = ASHTTP.post_form(url, password: params[:password])

    if JSON.parse(response.code) == 200
      session[:session] = JSON.parse(response.body)['session']
      session[:username] = JSON.parse(response.body)['user']['username']
      redirect_to ('/'), :notice => "Logged in as #{session[:username]}!"
    else
      flash.now[:alert] = "Invalid."
      raise LoginFailedException.new("#{response.code}: #{response.body}")
      redirect_to ('/')
    end
  end

  def logout
    uri = "/logout"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    JSONModel::HTTP.post_json(url, {}.to_json)
    session[:session] = nil
    session[:username] = nil
    redirect_to ('/')
  end
end
