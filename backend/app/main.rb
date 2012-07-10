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
  end


  # Load all controllers
  Dir.glob(File.join(File.dirname($0), "controllers", "*.rb")).each do |controller|
    load File.absolute_path(controller)
  end


  configure do
    set :raise_errors, Proc.new { false }
    set :show_exceptions, false

    set :logging, true

    DB.connect
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
