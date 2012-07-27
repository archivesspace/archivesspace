class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_repository_list

  def load_repository_list
    @repositories = JSONModel(:repository).all

    if not session.has_key?(:repo) and @repositories
      session[:repo] = @repositories.first.id.to_s
      session[:repo_id] = @repositories.first.repo_id
    end
  end

end
