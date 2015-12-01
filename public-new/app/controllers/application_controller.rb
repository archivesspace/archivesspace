require 'memoryleak'


class ApplicationController < ActionController::API
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  before_filter :establish_session
  before_filter :assign_repositories

  rescue_from RecordNotFound, :with => :handle_404


  def handle_404
    if env["REQUEST_PATH"] =~ /^\/api/
      render :json => {:error => "not-found"}.to_json, :status => 404
    else
      render "errors/404"
    end
  end


  def establish_session
    Thread.current[:backend_session] = BackendSession.get_active_session
  end

  def reestablish_session
    Thread.current[:backend_session] = nil
    BackendSession.refresh_active_session

    establish_session
    redirect_to request.url
  end


  protected

  def assign_repositories
    @repositories = MemoryLeak::Resources.get(:repository)
  end

end
