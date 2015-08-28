require 'bundler'
Bundler.require

if ENV['COVERAGE_REPORTS'] && ENV["ASPACE_INTEGRATION"] == "true"
  require 'aspace_coverage'
  ASpaceCoverage.start('backend_integration')
end

require_relative 'lib/bootstrap'
ASpaceEnvironment.init

require_relative 'lib/uri_resolver'
require_relative 'lib/rest'
require_relative 'lib/crud_helpers'
require_relative 'lib/notifications'
require_relative 'lib/background_job_queue'
require_relative 'lib/export'
require_relative 'lib/request_context'
require_relative 'lib/reports/report_helper'
require_relative 'lib/component_transfer'
require_relative 'lib/progress_ticker'
require_relative 'lib/resequencer'

require 'solr_snapshotter'

require 'barcode_check'

require 'uri'
require 'sinatra/base'

class ArchivesSpaceService < Sinatra::Base

  include URIResolver
  include RESTHelpers

  include CrudHelpers

  include RESTHelpers::ResponseHelpers
  include Exceptions::ResponseMappings

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
    config.dont_reload File.join("**", "exporters", "*.rb")
    config.dont_reload File.join("**", "spec", "*.rb")

    set :server, :puma
  end

  configure :test do |config|
    set :server, :puma
  end


  configure do
    begin
      require_relative "model/db"
      DB.connect


      require_relative "model/backend_enum_source"
      JSONModel::init(:allow_other_unmapped => AppConfig[:allow_other_unmapped],
                      :enum_source => BackendEnumSource)


      # We'll handle these ourselves
      disable :sessions

      set :raise_errors, Proc.new { false }
      set :show_exceptions, false
      set :logging, false

      if !DB.connected?
        Log.error("***** DATABASE CONNECTION FAILED *****\n" +
                  "\n" +
                  "ArchivesSpace could not connect to your specified database URL (#{AppConfig[:db_url]}).\n\n" +
                  "Please check your configuration and try again.")
        raise "Database connection failed"
      end

      require_relative "model/ASModel"
      
      if AppConfig[:enable_jasper] 
        require_relative 'model/reports/jasper_report' 
        require_relative 'model/reports/jasper_report_register' 
        JasperReport.compile if AppConfig[:compile_jasper] 
        JasperReportRegister.register_reports
      end


      [File.dirname(__FILE__), *ASUtils.find_local_directories('backend')].each do |prefix|
        ['model/mixins', 'model', 'model/reports', 'controllers'].each do |path|
          Dir.glob(File.join(prefix, path, "*.rb")).sort.each do |file|
            require File.absolute_path(file)
          end
        end
      end

      # Start the notifications background delivery thread
      Notifications.init if ASpaceEnvironment.environment != :unit_test

      BackgroundJobQueue.init if ASpaceEnvironment.environment != :unit_test


      if ASpaceEnvironment.environment == :production
        # Start the job scheduler
        if !settings.respond_to? :scheduler?
          Log.info("Starting job scheduler")
          set :scheduler, Rufus::Scheduler.start_new
        end


        settings.scheduler.cron("0 * * * *", :tags => 'expiry') do
          Log.info("Expiring old notifications")
          Notifications.expire_old_notifications
          Log.info("Done")

          Log.info("Expiring old sessions")
          Session.expire_old_sessions
          Log.info("Done")
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

        if AppConfig[:enable_solr] && AppConfig[:solr_backup_schedule] && AppConfig[:solr_backup_number_to_keep] > 0
          settings.scheduler.cron(AppConfig[:solr_backup_schedule],
                                  :tags => 'solr_backup') do
            Log.info("Creating snapshot of Solr index and indexer state")
            SolrSnapshotter.snapshot
          end
        end
      end

      ANONYMOUS_USER = AnonymousUser.new

      require_relative "lib/bootstrap_access_control"

      Preference.init

      @loaded_hooks.each do |hook|
        hook.call
      end
      @archivesspace_loaded = true


      # Load plugin init.rb files (if present)
      ASUtils.find_local_directories('backend').each do |dir|
        init_file = File.join(dir, "plugin_init.rb")
        if File.exists?(init_file)
          load init_file
        end
      end


      Notifications.notify("BACKEND_STARTED")
      Log.noisiness "Logger::#{AppConfig[:backend_log_level].upcase}"
      Resequencer.run( [ :ArchivalObject,  :DigitalObjectComponent, :ClassificationTerm ] ) if AppConfig[:resequence_on_startup]

    rescue
      ASUtils.dump_diagnostics($!)
    end
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


      env[:aspace_user] = ANONYMOUS_USER

      if session
        env[:aspace_session] = session
        env[:aspace_user] = ((session && session[:user] && User.find(:username => session[:user])) ||
                             ANONYMOUS_USER)
      end

      querystring = env['QUERY_STRING'].empty? ? "" : "?#{Log.filter_passwords(env['QUERY_STRING'])}"

      Log.debug("#{env['REQUEST_METHOD']} #{env['PATH_INFO']}#{querystring} [session: #{session.inspect}]")
      result = @app.call(env)

      end_time = Time.now

      Log.debug("Responded with #{result.to_s[0..512]}... in #{(end_time - start_time) * 1000}ms")

      result
    end
  end


  use RequestWrappingMiddleware


  before do
    # No caching!
    cache_control :private, :must_revalidate, :max_age => 0
  end


  get '/' do
    sys_info =  DB.sysinfo.merge({ "archivesSpaceVersion" =>  ASConstants.VERSION}) 
    
    request.accept.each do |type|
        case type
          when 'application/json'
            content_type :json 
            halt sys_info.to_json
        end
    end  
    JSON.pretty_generate(sys_info )
  end


  get '/doc' do
    erb :endpoint_doc
  end

end


if $0 == __FILE__
  Log.info("Dev server starting up...")

  ArchivesSpaceService.run!(:port => (ARGV[0] or 4567)) do |server|
    def server.stop
      # Shutdown long polling threads that would otherwise hold things up.
      Notifications.shutdown
      RealtimeIndexing.shutdown

      super
    end
  end
end
