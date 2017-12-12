require 'aspace_logger'
# This is a class used for logging in sinatra applications ( backend, indexer
# ). Rails provides its own logging functionality, so its not needed in the
# Frontend or PUI
class Log


  # By default start with STDERR, but allow people to change it. 
  @@logger =  ASpaceLogger.new($stderr)
  
  def self.logger(log) 
    @@logger =  ASpaceLogger.new(log)
  end
  
  def self.noisiness(log_level)
    @@logger.sev_threshold = log_level
  end

  def self.quiet_please
    @@logger.sev_threshold = Logger::FATAL
  end

  def self.exception(e)
    backtrace = e.backtrace.join("\n")
    @@logger.error("\n#{e}\n#{backtrace}")
  end

  def self.prepare(s)
    my_id = "Thread-#{Thread.current.object_id}"
    "#{my_id}: #{s}"
  end

  def self.debug(s) @@logger.debug(prepare(s)) end
  def self.info(s) @@logger.info(prepare(s)) end
  def self.warn(s) @@logger.warn(prepare(s)) end
  def self.error(s) @@logger.error(prepare(s)) end

  # this gets the backlog and starts the recording timer
  def self.backlog
    @@logger.backlog_and_flush 
  end

  def self.filter_passwords(params)
    if params.is_a? String
      params.gsub(/password=(.*?)(&|$)/, "password=[FILTERED]")
    else
      params = params.clone

      ["password", :password].each do|param|
        if params[param]
          params[param] = "[FILTERED]"
        end
      end

      params
    end
  end

end
