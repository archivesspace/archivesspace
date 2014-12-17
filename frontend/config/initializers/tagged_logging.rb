module ActiveSupport  

  class TaggedLogging 

    def backlog
      if @logger.respond_to?(:backlog_and_flush)
        @logger.backlog_and_flush
      end
    end


  end
end
