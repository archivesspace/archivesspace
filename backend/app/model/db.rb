class DB

  def self.connect
    if not @pool
      @pool = Sequel.connect(AppConfig[:db_url],
                             :max_connections => AppConfig[:db_max_connections],
                             # :loggers => [Logger.new($stderr)]
                             )
    end
  end


  class RollbackWithResponse < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end


  def self.rollback_and_return(response)
    raise RollbackWithResponse.new(response)
  end


  def self.open(transaction = true)
    last_err = false

    5.times do
      begin
        if transaction
          begin
            @pool.transaction do
              return yield @pool
            end
          rescue RollbackWithResponse => e
            return e.response
          end

          # Sometimes we'll make it to here.  That means we threw a
          # Sequel::Rollback which has been quietly caught.
          return
        else
          return yield @pool
        end

      rescue Sequel::DatabaseDisconnectError => e
        # MySQL might have been restarted.
        last_err = e
        Log.info("Connecting to the database failed.  Retrying...")
        sleep(3)
      end
    end

    if last_err
      Log.error("Failed to connect to the database")
      Log.exception(last_err)

      raise "Failed to connect to the database: #{last_err}"
    end
  end


  # Yeesh.
  def self.is_integrity_violation(exception)
    return exception.wrapped_exception.cause.getSQLState() =~ /^23/
  end


  def self.disconnect
    @pool.disconnect
  end
end
