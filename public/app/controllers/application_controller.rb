require 'memoryleak'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_repository_list

  rescue_from RecordNotFound, :with => :handle_404
  rescue_from Errno::ECONNREFUSED, :with => :handle_backend_down

  def load_repository_list
    unless request.path == '/webhook/notify'
      @repositories = MemoryLeak::Resources.get(:repository)

      # Make sure the user's selected repository still exists.
      if params[:repo] 
        repo = @repositories.detect(false) {|repo| repo.repo_code == params[:repo]}
        if repo
          @repository = repo
        else
          redirect_to :root
        end
      end
    end
  end


  def handle_404
    render "errors/404"
  end


  def handle_backend_down
    render "errors/backend_down"
  end

end
