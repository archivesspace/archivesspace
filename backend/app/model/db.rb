class DB

  def self.connect
    @pool = Sequel.connect(AppConfig::DB_URL,
                           :max_connections => AppConfig::DB_MAX_CONNECTIONS,
                           # :loggers => [Logger.new($stderr)]
                           )
  end


  def self.open(transaction = true)
    last_err = false

    5.times do
      begin
        if transaction
          @pool.transaction do
            return yield @pool
          end
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

    Log.error("Failed to connect to the database")
    Log.exception(last_err)

    raise "Failed to connect to the database: #{last_err}"
  end


  # Yeesh.
  def self.is_integrity_violation(exception)
    return exception.wrapped_exception.cause.getSQLState() =~ /^23/
  end


  def self.disconnect
    @pool.disconnect
  end
end
