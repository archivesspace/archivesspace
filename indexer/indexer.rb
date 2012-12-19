require_relative 'periodic_indexer'
require_relative 'realtime_indexer'

def main
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


  periodic_indexer.run
  threads.each {|t| t.join}
end


main
