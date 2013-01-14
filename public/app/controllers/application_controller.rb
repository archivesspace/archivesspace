require 'memoryleak'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :establish_session

  before_filter :load_repository_list

  rescue_from RecordNotFound, :with => :handle_404
  rescue_from Errno::ECONNREFUSED, :with => :handle_backend_down

  def load_repository_list
    unless request.path == '/webhook/notify'
      @repositories = MemoryLeak::Resources.get(:repository)

      # Make sure the user's selected repository still exists.
      if params[:repo] 
        repo = @repositories.detect(false) {|repo| repo.repo_code.downcase == params[:repo].downcase}
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


  def establish_session
    if session[:session]
      Thread.current[:backend_session] = session[:session]
      return session[:session]
    end

    username = AppConfig[:search_username]
    password = AppConfig[:search_user_secret]

    url = URI.parse(AppConfig[:backend_url] + "/users/#{username}/login")

    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data("expiring" => "false",
                          "password" => password)

    response = JSONModel::HTTP.do_http_request(url, request)

    if response.code == '200'
      auth = JSON.parse(response.body)

      session[:session] = auth['session']
      Thread.current[:backend_session] = auth['session']

    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end

end
