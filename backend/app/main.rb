require_relative 'lib/bootstrap'

require 'sinatra/base'
require 'json'


class ArchivesSpaceService < Sinatra::Base

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


  error MissingParamsException do
    json_response({:error => request.env['sinatra.error']}, 400)
  end

  error ConflictException do
    json_response({:error => request.env['sinatra.error']}, 409)
  end



  helpers do
    def ensure_params(required_params)
      required_params = required_params[0]

      missing = []
      required_params.each do |parameter, opts|
        if not params[parameter]
          missing << parameter
        end
      end

      if not missing.empty?
        s = "Your request was missing the following required parameters:\n\n"

        missing.each do |param|
          s += "  * #{param} -- #{required_params[param][:doc]}\n"
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
