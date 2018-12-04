require 'net/http'
# This is a faked response for a solr timeout. Why? In some cases, Solr will
# timeout, but there will be no response. Instead Ruby will raise a
# Timeout::Error, which the indexer does not handle, causing the indexer to
# crash in the index round. Instead we will rescue the timeout error and return
# this faked response.
class FakeSolrTimeoutResponse < Net::HTTPRequestTimeOut

    def initialize(req)
      @req = req 
      super('1.0', '408', 'SOLR TIMEOUT ERROR') 
    end
    
    
    # This needs to be added so Net::HTTP stream check passes.
    def read_body(*args, &block)
      @body = "
Timeout error with #{@req.uri} #{@req.method} #{@req.body}.
Please check your :indexer_solr_timeout_seconds, :indexer_thread_count, and :indexer_records_per_thread settings in 
your config.rb file.
Also check https://wiki.apache.org/solr/SolrPerformanceProblems for possible performance issues.
      " 
      yield @body if block_given?
      @body
    end

end
