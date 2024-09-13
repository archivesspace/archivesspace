require 'fileutils'
require 'rbconfig'

if AppConfig[:db_url] =~ /jdbc:mysql/
  require "db/sequel_mysql_timezone_workaround"
end

class DB

  Sequel.database_timezone = :utc
  Sequel.typecast_timezone = :utc

  SUPPORTED_DATABASES = [
                         {
                           :pattern => /jdbc:mysql/,
                           :name => "MySQL"
                         },
                         {
                           :pattern => /jdbc:derby/,
                           :name => "Apache Derby"
                         }
                        ]

  class DBPool
    DATABASE_READ_ONLY_REGEX = /is read only|server is running with the --read-only option/

    attr_reader :pool_size, :pool_timeout

    def initialize(pool_size = AppConfig[:db_max_connections], pool_timeout = AppConfig[:db_pool_timeout], opts = {})
      @pool_size = pool_size
      @pool_timeout = pool_timeout
      @opts = opts

      @lock = Mutex.new
    end

    def connect
      if not @pool

        if !AppConfig[:allow_unsupported_database]
          check_supported(AppConfig[:db_url])
        end

        begin
          Log.info("Connecting to database: #{AppConfig[:db_url_redacted]}. Max connections: #{pool_size}")
          pool = Sequel.connect(AppConfig[:db_url],
                                :max_connections => pool_size,
                                :pool_timeout => pool_timeout,
                                :test => true,
                                :loggers => (AppConfig[:db_debug_log] ? [Logger.new($stderr)] : [])
                               )

          # Test if any tables exist
          pool[:schema_info].all

          if !@opts[:skip_utf8_check] && pool.database_type == :mysql && !AppConfig[:allow_non_utf8_mysql_database]
            ensure_tables_are_utf8(pool)
          end

          @pool = pool
        rescue Sequel::DatabaseConnectionError
          Log.error("DB connection failed: #{$!}")

          exceptions = [$!.wrapped_exception].compact

          while !exceptions.empty?
            exception = exceptions.shift
            Log.error("Additional DB info: #{exception.inspect}: #{exception}")
            exceptions << exception.get_cause if exception.get_cause
          end

          raise
        rescue
          Log.error("DB connection failed: #{$!}")
          raise
        end
      end

      self
    end


    def connected?
      not @pool.nil?
    end

    def transaction(*args)
      retry_count = 0

      begin
        # @pool might be nil if we're in the middle of a reconnect.  Spin for a
        # bit before giving up.
        pool = nil

        60.times do
          pool = @pool
          break if pool
          sleep 1
        end

        if pool.nil?
          Log.info("DB connection failed: unable to get a connection")
          raise
        end

        pool.transaction(*args) do
          yield(pool)
        end
      rescue Sequel::DatabaseError, java.sql.SQLException => e
        if retry_count > 0
          Log.warn("DB connection failure: #{e}.  Retry count is #{retry_count}")
        end

        if retry_count > 6
          # We give up
          raise e
        end

        if e.to_s =~ DATABASE_READ_ONLY_REGEX
          sleep rand * 10

          # Reset the pool...
          old_pool = @pool

          @lock.synchronize do
            if @pool == old_pool
              # If we got the lock and nobody has reset the pool yet, it's time to do our thing.
              @pool = nil

              # We retry the connection indefinitely here.  The system isn't
              # going to function until the pool is restored, so either return
              # successful or don't return at all.
              begin
                connect
              rescue
                Log.warn("DB connection failure on reconnect: #{$!}.  Retrying indefinitely...")
                sleep 1
                retry
              end
            end
          end

          retry_count += 1
          retry
        else
          raise e
        end
      end
    end


    def after_commit(&block)
      if @pool.in_transaction?
        @pool.after_commit do
          block.call
        end
      else
        block.call
      end
    end


    def session_storage
      Thread.current[:db_session_storage] or raise "Not inside transaction!"
    end

    def open(transaction = true, opts = {})
      # Give us a place to hang storage that relates to the current database
      # session.
      Thread.current[:db_session_storage] ||= {}
      Thread.current[:nesting_level] ||= 0
      Thread.current[:nesting_level] += 1

      Thread.current[:in_transaction] ||= false

      begin
        if Thread.current[:in_transaction] && ASpaceEnvironment.environment != :unit_test
          # We are already inside another DB.open that will handle all
          # exceptions and retries for us.  We want to avoid a situation like
          # this:
          #
          # transaction scope / DB.open do |db|
          #                   |   db[:sometable].insert(foo)
          #                   |
          #                   |   DB.open do |db|                                         \
          #                   |     db[:sometable].insert(something_that_depends_on_foo)  | retry scope
          #                   |   end                                                     /
          #                   \ end
          #
          # Despite the nested DB.open calls, Sequel's default behavior is to
          # merge the inner call to DB.transaction with the already active
          # transaction.
          #
          # If the inner "retry scope" hits an exception, the whole transaction
          # is rolled back (all of "transaction scope", including the insert of
          # `foo`), but only the inner "retry scope" is retried.  If that
          # succeeds on the retry, we end up losing first insert and keeping the
          # second.
          #
          # So the fix here is to let the outermost DB.open take responsibility
          # for everything: make the retry scope and the transaction scope line
          # up with each other.

          return yield @pool
        end

        last_err = false
        retries = opts[:retries] || 10

        retries.times do |attempt|
          begin
            if transaction
              self.transaction(:isolation => opts.fetch(:isolation_level, :repeatable)) do
                Thread.current[:in_transaction] = true
                begin
                  return yield @pool
                ensure
                  Thread.current[:in_transaction] = false
                end
              end

              # Sometimes we'll make it to here.  That means we threw a
              # Sequel::Rollback which has been quietly caught.
              return nil
            else
              begin
                return yield @pool
              rescue Sequel::Rollback
                # If we're not in a transaction we can't roll back, but no need to blow up.
                Log.warn("Sequel::Rollback caught but we're not inside of a transaction")
                return nil
              end
            end


          rescue Sequel::DatabaseDisconnectError => e
            # MySQL might have been restarted.
            last_err = e
            Log.info("Connecting to the database failed.  Retrying...")
            sleep(opts[:db_failed_retry_delay] || 3)


          rescue Sequel::NoExistingObject, Sequel::DatabaseError => e
            if (attempt + 1) < retries && is_retriable_exception(e, opts) && transaction
              Log.info("Retrying transaction after retriable exception (#{e})")
              sleep(opts[:retry_delay] || 1)
            else
              raise e
            end
          end

          if last_err
            Log.error("Failed to connect to the database")
            Log.exception(last_err)

            raise "Failed to connect to the database: #{last_err}"
          end
        end
      ensure
        Thread.current[:nesting_level] -= 1

        if Thread.current[:nesting_level] <= 0
          Thread.current[:db_session_storage] = nil
        end
      end
    end

    def in_transaction?
      @pool.in_transaction?
    end

    def sysinfo
      jdbc_metadata.merge(system_metadata).merge({ "archivesSpaceVersion" => ASConstants.VERSION})
    end


    def jdbc_metadata
      md = open { |p| p.synchronize { |c| c.getMetaData }}
      { "databaseProductName" => md.getDatabaseProductName,
        "databaseProductVersion" => md.getDatabaseProductVersion }
    end

    def system_metadata
      RbConfig.const_get("CONFIG").select { |key| ['host_os', 'host_cpu',
                                                   'build', 'ruby_version'].include? key }.merge({
                                                      'java.runtime.name' => java.lang.System.getProperty('java.runtime.name'),
                                                      'java.version' => java.lang.System.getProperty('java.version')
                                                    })
    end

    def needs_savepoint?
      # Postgres needs a savepoint for any statement that might fail
      # (otherwise the whole transaction becomes invalid).  Use a savepoint to
      # run the happy case, since we're half expecting it to fail.
      [:postgres].include?(@pool.database_type)
    end


    class DBAttempt

      def initialize(happy_path)
        @happy_path = happy_path
      end


      def and_if_constraint_fails(&failed_path)
        begin
          DB.transaction(:savepoint => DB.needs_savepoint?) do
            @happy_path.call
          end
        rescue Sequel::DatabaseError => ex
          if DB.is_integrity_violation(ex)
            failed_path.call(ex)
          else
            raise ex
          end
        rescue Sequel::ValidationFailed => ex
          failed_path.call(ex)
        end
      end

    end


    def attempt(&block)
      DBAttempt.new(block)
    end


    # Yeesh.
    def is_integrity_violation(exception)
      (exception.wrapped_exception.cause or exception.wrapped_exception).getSQLState() =~ /^23/
    end


    def is_retriable_exception(exception, opts = {})
      # Transaction was rolled back, but we can retry
      return true if exception.instance_of?(RetryTransaction)

      return true if (opts[:retry_on_optimistic_locking_fail] && exception.instance_of?(Sequel::Plugins::OptimisticLocking::Error))

      if (inner_exception = exception.wrapped_exception)
        if inner_exception.cause
          inner_exception = inner_exception.cause
        end

        if inner_exception.is_a?(java.sql.SQLException)
          return inner_exception.getSQLState =~ /^(40|41)/
        end
      end

      false
    end

    def disconnect
      @pool.disconnect
    end


    def check_supported(url)
      if !SUPPORTED_DATABASES.any? {|db| url =~ db[:pattern]}

        msg = <<~eof

          =======================================================================
          UNSUPPORTED DATABASE
          =======================================================================

          The database listed in your configuration:

            #{url}

          is not officially supported by ArchivesSpace.  Although the system may
          still work, there's no guarantee that future versions will continue to
          work, or that it will be possible to upgrade without losing your data.

          It is strongly recommended that you run ArchivesSpace against one of
          these supported databases:

        eof

        SUPPORTED_DATABASES.each do |db|
          msg += "  * #{db[:name]}\n"
        end

        msg += "\n"
        msg += <<~eof

          To ignore this (very good) advice, you can set the configuration option:

            AppConfig[:allow_unsupported_database] = true


          =======================================================================

        eof

        Log.error(msg)

        raise "Database not supported"
      end
    end


    def backups_dir
      AppConfig[:backup_directory]
    end


    def expire_backups
      backups = []
      Dir.foreach(backups_dir) do |filename|
        if filename =~ /^demo_db_backup_[0-9]+_[0-9]+$/
          backups << File.join(backups_dir, filename)
        end
      end

      expired_backups = backups.sort.reverse.drop(AppConfig[:demo_db_backup_number_to_keep])

      expired_backups.each do |backup_dir|
        # Proudly paranoid
        if File.exist?(File.join(backup_dir, "archivesspace_demo_db", "BACKUP.HISTORY"))
          Log.info("Expiring old backup: #{backup_dir}")
          FileUtils.rm_rf(backup_dir)
        else
          Log.warn("Too cowardly to delete: #{backup_dir}")
        end
      end
    end


    def demo_db_backup
      # Timestamp must come first here for filenames to sort chronologically
      this_backup = File.join(backups_dir, "demo_db_backup_#{Time.now.to_i}_#{$$}")

      Log.info("Writing backup to '#{this_backup}'")

      @pool.pool.hold do |c|
        cs = c.prepare_call("CALL SYSCS_UTIL.SYSCS_BACKUP_DATABASE(?)")
        cs.set_string(1, this_backup.to_s)
        cs.execute
        cs.close
      end

      expire_backups
    end


    def increase_lock_version_or_fail(obj)
      updated_rows = obj.class.dataset.filter(:id => obj.id, :lock_version => obj.lock_version).
                     update(:lock_version => obj.lock_version + 1,
                            :system_mtime => Time.now)

      if updated_rows != 1
        raise Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of: #{obj}")
      end
    end


    def supports_mvcc?
      ![:derby, :h2].include?(@pool.database_type)
    end


    def supports_join_updates?
      ![:derby, :h2].include?(@pool.database_type)
    end


    def needs_blob_hack?
      (@pool.database_type == :derby)
    end

    def blobify(s)
      (@pool.database_type == :derby) ? s.to_sequel_blob : s
    end


    def concat(s1, s2)
      if @pool.database_type == :derby
        "#{s1} || #{s2}"
      else
        "CONCAT(#{s1}, #{s2})"
      end
    end


    def ensure_tables_are_utf8(db)
      non_utf8_tables = db[:information_schema__tables].
                        join(:information_schema__collation_character_set_applicability, :collation_name => :table_collation).
                        filter(:table_schema => Sequel.function(:database)).
                        filter(~Sequel.like(:character_set_name, 'utf8%')).all

      unless (non_utf8_tables.empty?)
        msg = <<~EOF

          The following MySQL database tables are not set to use UTF-8 for their character
          encoding:

          #{non_utf8_tables.map {|t| "  * " + t[:TABLE_NAME]}.join("\n")}

          Please refer to README.md for instructions on configuring your database to use
          UTF-8.

          If you want to override this restriction (not recommended!) you can set the
          following option in your config.rb file:

            AppConfig[:allow_non_utf8_mysql_database] = true

          But note that ArchivesSpace largely assumes that your data will be UTF-8
          encoded.  Running in a non-UTF-8 configuration is not supported.

        EOF

        Log.warn(msg)
        raise msg
      end

      Log.info("All tables checked and confirmed set to UTF-8.  Nice job!")
    end
  end


  # Create our default connection pool
  @default_pool = :not_connected

  def self.connect
    if @default_pool == :not_connected
      @default_pool = DBPool.new.connect
    else
      @default_pool
    end
  end

  def self.connected?
    if @default_pool == :not_connected
      false
    else
      @default_pool.connected?
    end
  end

  # Any method called on DB is dispatched to our default pool.
  DBPool.instance_methods(false).each do |method|
    if self.singleton_methods(false).include?(method)
      next
    end

    self.define_singleton_method(method) do |*args, &block|
      if block
        @default_pool.send(method, *args, &block)
      else
        @default_pool.send(method, *args)
      end
    end
  end

end
