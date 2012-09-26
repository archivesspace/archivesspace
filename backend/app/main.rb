require_relative 'lib/bootstrap'
require_relative 'lib/rest'
require_relative 'lib/crud_helpers'
require 'uri'

require 'sinatra/base'
require 'json'


class ArchivesSpaceService < Sinatra::Base

  include RESTHelpers
  include CrudHelpers



  configure :development do |config|
    require 'sinatra/reloader'
    register Sinatra::Reloader
    config.also_reload File.join("app", "**", "*.rb")
    config.dont_reload File.join("app", "lib", "rest.rb")
    config.dont_reload File.join("**", "migrations", "*.rb")
    config.dont_reload File.join("**", "spec", "*.rb")
  end


  configure do

    JSONModel::init

    require_relative "model/db"

    DB.connect

    unless DB.connected?
      puts "\n============================================\n"
      puts "DATABASE CONNECTION FAILED"
      puts ""
      puts "This system isn't going to do very much until its database turns up."
      puts ""
      puts "You will need to specify your database in:\n\n"
      puts "  #{AppConfig.find_user_config}"
      puts "\nor point your browser to the '/setup' URL on the backend (e.g. http://localhost:4567/setup)"
      puts "\n============================================\n"
    end

    # We'll handle these ourselves
    disable :sessions

    if DB.connected?
      # Load all models
      require_relative "model/ASModel"
      require_relative "model/identifiers"
      require_relative "model/external_documents"
      require_relative "model/subjects"
      require_relative "model/extents"
      require_relative "model/dates"
      Dir.glob(File.join(File.dirname(__FILE__), "model", "*.rb")).sort.each do |model|
        basename = File.basename(model, ".rb")
        require_relative File.join("model", basename)
      end

      # Load all controllers
      Dir.glob(File.join(File.dirname(__FILE__), "controllers", "*.rb")).sort.each do |controller|
        load File.absolute_path(controller)
      end

    else
      # Just load the setup controller
      load File.absolute_path(File.join(File.dirname(__FILE__), "controllers", "setup.rb"))
    end

    set :raise_errors, Proc.new { false }
    set :show_exceptions, false
    set :logging, false


    ANONYMOUS_USER = AnonymousUser.new


    require_relative "lib/bootstrap_access_control"


    # Ensure that the frontend is registered
    Array(AppConfig[:frontend_url]).each do |url|
      Webhooks.add_listener(URI.join(url, "/webhook/notify").to_s)
    end

    Webhooks.start
    Webhooks.notify("BACKEND_STARTED")
  end


  def handle_exception!(boom)
    @env['sinatra.error'] = boom
    status boom.respond_to?(:code) ? Integer(boom.code) : 500

    if not_found?
      headers['X-Cascade'] = 'pass'
      body '<h1>Not Found</h1>'
      return
    end

    res = error_block!(boom.class, boom) || error_block!(status, boom)

    if res
      DB.rollback_and_return(res)
    else
      raise boom
    end
  end


  error NotFoundException do
    json_response({:error => request.env['sinatra.error']}, 404)
  end

  error BadParamsException do
    json_response({:error => request.env['sinatra.error'].params}, 400)
  end

  error ValidationException do
    json_response({
                    :error => request.env['sinatra.error'].errors,
                    :warning => request.env['sinatra.error'].warnings,
                    :invalid_object => request.env['sinatra.error'].invalid_object.inspect
                  }, 400)
  end

  error ConflictException do
    json_response({:error => request.env['sinatra.error'].conflicts}, 409)
  end

  error AccessDeniedException do
    json_response({:error => "Access denied"}, 403)
  end

  error Sequel::ValidationFailed do
    json_response({:error => request.env['sinatra.error'].errors}, 409)
  end

  error Sequel::DatabaseError do
    json_response({:error => {:db_error => ["Database integrity constraint conflict: #{request.env['sinatra.error']}"]}}, 409)
  end

  error JSON::ParserError do
    json_response({:error => "Had some trouble parsing your request: #{request.env['sinatra.error']}"}, 400)
  end


  def session
    env[:aspace_session]
  end


  def current_user
    env[:aspace_user]
  end


  def filter_passwords(params)
    params = params.clone

    ["password", :password].each do|param|
      if params[param]
        params[param] = "[FILTERED]"
      end
    end

    params
  end


  helpers do

    # Redispatch the current request to a different route handler.
    def redirect_internal(url)
      call! env.merge("PATH_INFO" => url)
    end


    def json_response(obj, status = 200)
      [status, {"Content-Type" => "application/json"}, [obj.to_json + "\n"]]
    end


    def modified_response(type, obj, jsonmodel = nil)
      response = {:status => type, :id => obj[:id]}

      if jsonmodel
        response[:uri] = jsonmodel.class.uri_for(obj[:id])
        response[:warnings] = jsonmodel._warnings
      end

      json_response(response)
    end


    def created_response(*opts)
      modified_response('Created', *opts)
    end


    def updated_response(*opts)
      modified_response('Updated', *opts)
    end

  end


  class RequestWrappingMiddleware
    def initialize(app)
      @app = app
    end

    # Wrap every call in our DB connection management code.  This should
    # transparently deal with database restarts, and gives us a spot to hang any
    # DB connection logic.
    #
    def call(env)
      start_time = Time.now
      session_token = env["HTTP_X_ARCHIVESSPACE_SESSION"]

      session = nil

      if session_token
        session = Session.find(session_token)

        if session.nil?
          return [412,
                  {"Content-Type" => "application/json"},
                  [{
                     :code => "SESSION_GONE",
                     :error => "No session found for #{session_token}"
                   }.to_json]]
        end
      end

      env[:aspace_session] = session
      env[:aspace_user] = ((session && session[:user] && User.find(:username => session[:user])) ||
                           ANONYMOUS_USER)

      if DB.connected?
        result = DB.open do
          @app.call(env)
        end
      else
        result = @app.call(env)
      end

      end_time = Time.now

      if ArchivesSpaceService.development?
        Log.debug("Responded with #{result} in #{(end_time - start_time) * 1000}ms")
      end

      result
    end
  end


  use RequestWrappingMiddleware


  get '/' do
    "Hello, ArchivesSpace!"
  end


  get '/doc' do
    erb :endpoint_doc
  end

end


if $0 == __FILE__
  Log.info("Dev server starting up...")

  ArchivesSpaceService.run!(:port => (ARGV[0] or 4567)) do |server|
    server.instance_eval do
      @config[:AccessLog] = []
    end
  end
end
