require_relative 'periodic_indexer'
require_relative 'realtime_indexer'

def main
  periodic_indexer = PeriodicIndexer.get_indexer
  realtime_indexer = RealtimeIndexer.new


  realtime = Thread.new do
    begin
      sleep 5      # A bit lame, but when both indexers try to log
                   # in simultaneously they generate an ugly
                   # (harmless) warning.
      realtime_indexer.run
    rescue
      puts "Realtime indexing error: #{$!}"
      raise $!
    end
  end

  periodic_indexer.run
  realtime.join
end


main
