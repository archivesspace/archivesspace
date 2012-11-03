class DB

  def self.connect
    if not @pool
      begin
        pool = Sequel.connect(AppConfig[:db_url],
                              :max_connections => AppConfig[:db_max_connections],
                              :test => true,
                              # :loggers => [Logger.new($stderr)]
                              )

        # Test if any tables exist
        pool[:schema_info].all

        @pool = pool
      rescue
        puts "DB connection failed: #{$!}"
      end
    end
  end

  def self.connected?
    not @pool.nil?
  end


  def self.open(transaction = true)
    last_err = false

    5.times do
      begin
        if transaction
          @pool.transaction do
            return yield @pool
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


      rescue Sequel::DatabaseError => e
        if e.wrapped_exception.getSQLState =~ /^40/
          # Transaction was rolled back, but we can retry
          sleep 1
        else
          raise e
        end
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
