require 'rubygems'
require 'sinatra/base'

require_relative 'lib/periodic_indexer'
require_relative 'lib/realtime_indexer'

class ArchivesSpaceIndexer < Sinatra::Base

  def self.main
    periodic_indexer = PeriodicIndexer.get_indexer

    threads = []

    AppConfig[:backend_instance_urls].each do |backend_url|
      threads << Thread.new do

        realtime_indexer = RealtimeIndexer.new(backend_url)

        begin
          # A bit lame, but when both indexers try to log
          # in simultaneously they generate an ugly
          # (harmless) warning.
          sleep 5

          realtime_indexer.run
        rescue
          puts "Realtime indexing error (#{backend_url}): #{$!}"
          raise $!
        end
      end
    end


    threads << Thread.new do
      periodic_indexer.run
    end
  end


  configure do
    main
  end
end
