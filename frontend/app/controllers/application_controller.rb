class ApplicationController < ActionController::Base
  protect_from_forgery

  # Note: This should be first!
  before_filter :store_user_session

  before_filter :load_repository_list


  def store_user_session
    Thread.current[:backend_session] = session[:session]
  end


  def load_repository_list
    @repositories = JSONModel(:repository).all

    if not session.has_key?(:repo) and @repositories
      session[:repo] = @repositories.first.id.to_s
      session[:repo_id] = @repositories.first.repo_id
    end
  end

end
