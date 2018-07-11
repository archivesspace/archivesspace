require 'logger'
require 'atomic'

class ASpaceLogger < Logger

  def initialize(logdev)                                                                                  
    @backlog = Atomic.new([]) 
    @recording = Atomic.new(false) 
    super(logdev) 
  end

  def add(severity, message = nil, progname = nil, &block)
   if @recording.value == true

     if !message
       if block
         message = block.call
       else
         # O_o
         #
         # https://ruby-doc.org/stdlib-2.1.0/libdoc/logger/rdoc/Logger.html#method-i-add
         # "Program name string. Can be omitted. Treated as a message if no message and block are given."
         message = progname
         progname = nil
       end
     end

     add_to_backlog(format_message(format_severity(severity), Time.now, progname, message))
   end

   super(severity, message, progname, &block)
  end

  def add_to_backlog( formatted_messsage )
    if @backlog.value.length > 100
      flush_backlog
      stop_recording
    else
      @backlog.update { |bl| bl << formatted_messsage } 
    end 
  end

  def backlog
    @backlog.value.join("")
  end

  def flush_backlog
    @backlog.update {  |bl| bl = [] }  
  end
 
  def start_recording
    return if @recording.value == true 
    @recording.update { |r|  r = true } 
  end
  
  def stop_recording
    return unless @recording.value == true 
    @recording.update { |r|  r = false } 
  end

  def backlog_and_flush
    backlog_cache = backlog
    flush_backlog
    start_recording
    backlog_cache
  end

end
