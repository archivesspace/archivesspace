require_relative 'lib/bootstrap'

require 'sinatra/base'
require 'json'


class ArchivesSpaceService < Sinatra::Base

  include JSONModel

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

  error JSONValidationException do
    json_response({:error => request.env['sinatra.error']}, 400)
  end

  error ConflictException do
    json_response({:error => request.env['sinatra.error']}, 409)
  end



  class DBWrappingMiddleware
    def initialize(app)
      @app = app
    end

    # Wrap every call in our DB connection management code.  This should
    # transparently deal with database restarts, and gives us a spot to hang any
    # DB connection logic.
    #
    def call(env)
      DB.open do
        @app.call(env)
      end
    end
  end


  use DBWrappingMiddleware


  helpers do

    def ensure_params(required_params)
      required_params = required_params[0]

      missing = []
      bad_type = []
      required_params.each do |parameter, opts|
        if not params[parameter]
          missing << parameter
        else

          if opts[:type]
            begin
              params[parameter] = (opts[:type] == Integer) ? Integer(params[parameter]) : params[parameter]
            rescue ArgumentError
              bad_type << parameter
            end
          end

        end
      end

      if not (missing.empty? and bad_type.empty?)
        s = "Your request had some invalid parameters:\n\n"

        (missing + bad_type).each do |param|
          s += "  * #{param} -- #{required_params[param][:doc]}"
          if required_params[param].has_key?(:type)
            s = " (type: #{required_params[param][:type]})"
          end
          s += "\n"
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

  end


  get '/' do
    session = Session.new()
    session.save

    "Hello, ArchivesSpace!"
  end

end


if $0 == __FILE__
  Log.info("Dev server starting up...")
  ArchivesSpaceService.run!
end
