require 'logger'

class Log
  @@logger = Logger.new($stderr)

  def self.quiet_please
    @@logger.sev_threshold = Logger::FATAL
  end

  def self.exception(e)
    backtrace = e.backtrace.join("\n")
    @@logger.error("\n#{e}\n#{backtrace}")
  end

  def self.debug(s) @@logger.debug(s) end
  def self.info(s) @@logger.info(s) end
  def self.warn(s) @@logger.warn(s) end
  def self.error(s) @@logger.error(s) end
end
