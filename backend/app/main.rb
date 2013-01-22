require_relative 'lib/bootstrap'
require_relative 'lib/rest'
require_relative 'lib/crud_helpers'
require_relative 'lib/export'
require_relative 'lib/request_context.rb'
require_relative 'lib/webrick_fix'
require_relative 'lib/import_helpers'
require 'uri'

require 'sinatra/base'
require 'json'

require 'rufus/scheduler'


class ArchivesSpaceService < Sinatra::Base

  include RESTHelpers
  include CrudHelpers
  include ImportHelpers

  helpers do
    include RESTHelpers::ResponseHelpers
  end


  @loaded_hooks = []
  @archivesspace_loaded = false

  def self.loaded_hook(&block)
    if @archivesspace_loaded
      block.call
    else
      @loaded_hooks << block
    end
  end


  configure :development do |config|
    require 'sinatra/reloader'
    register Sinatra::Reloader
    config.also_reload File.join("app", "**", "*.rb")
    config.dont_reload File.join("app", "lib", "rest.rb")
    config.dont_reload File.join("**", "migrations", "*.rb")
    config.dont_reload File.join("**", "spec", "*.rb")
    config.also_reload File.join("../", "migrations", "lib", "exporter.rb")
    config.also_reload File.join("../", "migrations", "serializers", "*.rb")
  end


  configure do

    require_relative "model/db"
    DB.connect

    require_relative "model/enumeration"
    JSONModel::init(:allow_other_unmapped => AppConfig[:allow_other_unmapped],
                    :enum_source => Enumeration)


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
      require_relative "model/dynamic_enums"
      require_relative "model/identifiers"
      require_relative "model/external_documents"
      require_relative "model/external_ids"
      require_relative "model/subjects"
      require_relative "model/extents"
      require_relative "model/dates"
      require_relative "model/rights_statements"
      require_relative "model/instances"
      require_relative "model/deaccessions"
      require_relative "model/agents"
      require_relative "model/trees"

      Dir.glob(File.join(File.dirname(__FILE__), "model", "*.rb")).sort.each do |model|
        basename = File.basename(model, ".rb")
        require_relative File.join("model", basename)
      end

      # Load all controllers
      Dir.glob(File.join(File.dirname(__FILE__), "controllers", "*.rb")).sort.each do |controller|
        load File.absolute_path(controller)
      end


      if !Thread.current[:test_mode] && ENV["ASPACE_INTEGRATION"] != "true"
        # Start the job scheduler
        if !settings.respond_to? :scheduler?
          Log.info("Starting job scheduler")
          set :scheduler, Rufus::Scheduler.start_new
        end


        if AppConfig[:db_url] == AppConfig.demo_db_url &&
            settings.scheduler.find_by_tag('demo_db_backup').empty?

          Log.info("Enabling backups for the embedded demo database " +
                   "running at schedule: #{AppConfig[:demo_db_backup_schedule]}")


          settings.scheduler.cron(AppConfig[:demo_db_backup_schedule],
                                  :tags => 'demo_db_backup') do
            Log.info("Starting backup of embedded demo database")
            DB.demo_db_backup
            Log.info("Backup of embedded demo database completed!")
          end
        end
      end

      @loaded_hooks.each do |hook|
        hook.call
      end
      @archivesspace_loaded = true

    else
      # Just load the setup controller
      load File.absolute_path(File.join(File.dirname(__FILE__), "controllers", "setup.rb"))
    end

    set :raise_errors, Proc.new { false }
    set :show_exceptions, false
    set :logging, false


    if DB.connected?
      ANONYMOUS_USER = AnonymousUser.new

      require_relative "lib/bootstrap_access_control"

      # Ensure that the frontend is registered
      Array(AppConfig[:frontend_url]).each do |url|
        Webhooks.add_listener(URI.join(url, "/webhook/notify").to_s)
      end

      Webhooks.start
      Webhooks.notify("BACKEND_STARTED")
    end

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

    res or raise boom
  end


  error ImportException do
    json_response({:error => request.env['sinatra.error'].to_s}, 400)
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
    json_response({:error => request.env['sinatra.error'].errors}, 400)
  end

  error ReferenceError do
    json_response({:error => request.env['sinatra.error']}, 400)
  end

  error Sequel::DatabaseError do
    json_response({:error => {:db_error => ["Database integrity constraint conflict: #{request.env['sinatra.error']}"]}}, 400)
  end

  error Sequel::Plugins::OptimisticLocking::Error do
    json_response({:error => "The record you tried to update has been modified since you fetched it."}, 409)
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


  def high_priority_request?
    env["HTTP_X_ARCHIVESSPACE_PRIORITY"] && (env["HTTP_X_ARCHIVESSPACE_PRIORITY"].downcase == "high")
  end


  class RequestWrappingMiddleware
    def initialize(app)
      @app = app
    end

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

        if session[:expirable] &&
            AppConfig[:session_expire_after_seconds].to_i >= 0 &&
            session.age > AppConfig[:session_expire_after_seconds].to_i
          Session.expire(session_token)
          session = nil
          return [412,
                  {"Content-Type" => "application/json"},
                  [{
                     :code => "SESSION_EXPIRED",
                     :error => "Session timed out for #{session_token}"
                   }.to_json]]
        else
          session.touch
        end
      end


      if DB.connected?
        env[:aspace_user] = ANONYMOUS_USER

        if session
          env[:aspace_session] = session
          env[:aspace_user] = ((session && session[:user] && User.find(:username => session[:user])) ||
                               ANONYMOUS_USER)
        end
      end

      querystring = env['QUERY_STRING'].empty? ? "" : "?#{Log.filter_passwords(env['QUERY_STRING'])}"

      Log.debug("#{env['REQUEST_METHOD']} #{env['PATH_INFO']}#{querystring} [session: #{session.inspect}]")
      result = @app.call(env)

      end_time = Time.now

      Log.debug("Responded with #{result.to_s.gsub(/^(.{1024}).+$/, '\\1...')} in #{(end_time - start_time) * 1000}ms")

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
