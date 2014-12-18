require 'logger'

class ASpaceLogger < Logger


  def initialize(logdev)                                                                                  
    @backlog = []
    @recorder = Time.now 
    super(logdev) 
  end

  def add(severity, message = nil, progname = nil, &block)
   orig = super(severity, message, progname, &block )
   add_to_backlog(  format_message(format_severity(severity), Time.now, progname, message)) 
   orig 
  end

  # by default, we'll always keep 20 lines. If in record mode, well capture
  # everyhing ( for 15 seconds ) 
  def add_to_backlog( formatted_messsage )
    @backlog.shift if ( @backlog.length > 20 or  @recorder - Time.now > 15 )
    @backlog << formatted_messsage 
  end

  def backlog
    @backlog.join("")
  end

  def flush_backlog
    @backlog = []
  end
 
  # Recording process will go for 30 seconds
  def start_recording
    @recorder = Time.now
  end

  def backlog_and_flush
    backlog_cache = backlog
    flush_backlog
    start_recording
    backlog_cache
  end


end
