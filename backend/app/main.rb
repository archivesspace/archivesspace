require_relative 'lib/bootstrap'

require 'sinatra/base'
require 'json'


class ArchivesSpaceService < Sinatra::Base

  include JSONModel


  register do
    def operation(type)
      condition do
        params[:operation] == type.to_s
      end
    end
  end


  configure :development do |config|

    # This is very possibly a dumb thing to do, but the reloader was having
    # trouble replacing the routes from the dynamically loaded controllers.
    self.instance_eval { @routes = {} }

    require 'sinatra/reloader'
    register Sinatra::Reloader
    config.also_reload File.join("**", "*.rb")
    config.dont_reload File.join("**", "migrations", "*.rb")
    config.dont_reload File.join("**", "spec", "*.rb")
  end


  configure do

    require_relative "model/db"
    DB.connect

    # We'll handle these ourselves
    disable :sessions

    # Load all models
    require_relative "model/ASModel"
    Dir.glob(File.join(File.dirname(__FILE__), "model", "*.rb")).each do |model|
      basename = File.basename(model, ".rb")
      require_relative File.join("model", basename)
    end

    # Load all controllers
    Dir.glob(File.join(File.dirname(__FILE__), "controllers", "*.rb")).each do |controller|
      load File.absolute_path(controller)
    end

    set :raise_errors, Proc.new { false }
    set :show_exceptions, false

    set :logging, true
  end



  error NotFoundException do
    json_response({:error => request.env['sinatra.error']}, 404)
  end

  error MissingParamsException do
    json_response({:error => request.env['sinatra.error']}, 400)
  end

  error ValidationException do
    json_response({:error => request.env['sinatra.error']}, 400)
  end

  error ConflictException do
    json_response({:error => request.env['sinatra.error'].conflicts}, 409)
  end

  error Sequel::ValidationFailed do
    json_response({:error => request.env['sinatra.error'].errors}, 409)
  end

  error Sequel::DatabaseError do
    json_response({:error => {:db_error => ["Database integrity constraint conflict: #{request.env['sinatra.error']}"]}}, 409)
  end


  def session
    @session
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
      session_token = env["HTTP_X_ARCHIVESSPACE_SESSION"]

      session = nil

      if session_token
        session = Session.find(session_token)
        Log.debug("Got session: #{session}")
      end

      @app.instance_eval {
        @session = session
      }

      DB.open do
        @app.call(env)
      end
    end
  end


  use RequestWrappingMiddleware


  helpers do

    def ensure_params(declared_params)
      declared_params = declared_params[0]

      body_param = declared_params.find {|param, opts| opts[:body]}

      if body_param
        params[body_param[0]] = request.body.read
      end

      errors = {
        :missing => [],
        :bad_type => []
      }

      declared_params.each do |parameter, opts|
        if not params[parameter] and not declared_params[parameter][:optional]
          errors[:missing] << parameter
        else

          if opts[:type] and params[parameter]
            begin
              params[parameter] = if opts[:type] == Integer
                                    Integer(params[parameter])
                                  elsif opts[:type].respond_to? :from_json
                                    opts[:type].from_json(params[parameter])
                                  else
                                    params[parameter]
                                  end
            rescue ArgumentError
              errors[:bad_type] << parameter
            end
          end

        end
      end

      if not errors.values.flatten.empty?
        s = "Your request parameters weren't quite right:\n\n"

        errors[:missing].each do |param|
          s += "  * Missing value for '#{param}' -- #{declared_params[param][:doc]}\n"
        end

        errors[:bad_type].each do |param|
          s += "  * Invalid type for '#{param}' -- Wanted type #{declared_params[param][:type]} but got '#{params[param]}'\n"
        end

        raise MissingParamsException.new(s)
      end
    end


    # Redispatch the current request to a different route handler.
    def redirect_internal(url)
      call! env.merge("PATH_INFO" => url)
    end


    def json_response(obj, status = 200)
      [status, {"Content-Type" => "application/json"}, JSON(obj)]
    end


    def created_response(id, warnings = {})
      json_response({:status => "Created", :id => id, :warnings => warnings})
    end

  end


  get '/' do
    "Hello, ArchivesSpace!"
  end

end


if $0 == __FILE__
  Log.info("Dev server starting up...")
  ArchivesSpaceService.run!
end
