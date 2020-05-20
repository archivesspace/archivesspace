require 'rubygems'
require 'sinatra/base'
require 'atomic'

require_relative 'lib/periodic_indexer'
require_relative 'lib/realtime_indexer'
require_relative 'lib/pui_indexer'

require 'archivesspace_thread_dump'
ArchivesSpaceThreadDump.init(File.join(ASUtils.find_base_directory, "thread_dump_indexer.txt"))
require 'active_support/inflector'

require 'log'
if AppConfig.changed?(:indexer_log)
  Log.logger(AppConfig[:indexer_log])
else
  Log.logger($stderr)
end


class ArchivesSpaceIndexer < Sinatra::Base

  def self.main
    periodic_indexer = PeriodicIndexer.get_indexer
    pui_indexer = PUIIndexer.get_indexer

    threads = []

    Log.info("Starting periodic indexer")
    threads << Thread.new do
      begin
        periodic_indexer.run
      rescue
        Log.error("Unexpected failure in periodic indexer: #{$!}")
      end
    end

    if AppConfig[:pui_indexer_enabled]
      Log.info "Starting PUI indexer"
      threads << Thread.new do
        # Stagger them to encourage them to run at different times
        sleep AppConfig[:solr_indexing_frequency_seconds]

        begin
          pui_indexer.run
        rescue
          Log.error "Unexpected failure in PUI indexer: #{$!}"
        end
      end
    end

    sleep 5

    backend_urls = Atomic.new([])

    threads << Thread.new do
      realtime_indexers = {}

      while true
        begin
          # Once a minute, check to see whether any new backend instances have
          # turned up
          backend_urls.update {|old_urls| AppConfig[:backend_instance_urls]}

          # Start up threads for any backends that don't have one yet
          backend_urls.value.each do |url|
            if !realtime_indexers[url] || !realtime_indexers[url].alive?

              Log.info "Starting realtime indexer for: #{url}"

              realtime_indexers[url] = Thread.new do
                begin
                  indexer = RealtimeIndexer.new(url, proc { backend_urls.value.include?(url) })
                  indexer.run
                rescue
                  Log.error "Realtime indexing error (#{backend_url}): #{$!}"
                  sleep 5
                end
              end
            end
          end

          sleep 60
        rescue
          sleep 5
        end
      end
    end


    threads.each {|t| t.join} if java.lang.System.get_property("aspace.devserver")
  end


  configure do
    begin
      # Load plugin init.rb files (if present)
      ASUtils.find_local_directories('indexer').each do |dir|
        init_file = File.join(dir, "plugin_init.rb")
        if File.exists?(init_file)
          load init_file
        end
      end
    rescue
      ASUtils.dump_diagnostics($!)
    end

    set :logging, false 
    Log.noisiness "Logger::#{AppConfig[:indexer_log_level].upcase}".constantize

    main
  end

  get "/" do
    if IndexerCommon.paused?
      "Indexers paused until #{IndexerCommon.class_variable_get(:@@paused_until)}"
    else
      "Running every #{AppConfig[:solr_indexing_frequency_seconds].to_i} seconds. "
    end
  end

  # this pauses the indexer so that bulk update and migrations can happen
  # without bogging down the server
  put "/" do
    duration = params[:duration].nil? ? 900 : params[:duration].to_i
    IndexerCommon.pause duration  
    "#{IndexerCommon.class_variable_get(:@@paused_until)}"
  end


end

