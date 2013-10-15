require 'fileutils'

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

  def self.connect
    if not @pool

      if !AppConfig[:allow_unsupported_database]
        check_supported(AppConfig[:db_url])
      end

      begin
        Log.info("Connecting to database: #{AppConfig[:db_url]}")
        pool = Sequel.connect(AppConfig[:db_url],
                              :max_connections => AppConfig[:db_max_connections],
                              :test => true,
                              #:loggers => [Logger.new($stderr)]
                              )

        # Test if any tables exist
        pool[:schema_info].all

        if pool.database_type == :mysql && AppConfig[:allow_non_utf8_mysql_database] != "true"
          ensure_tables_are_utf8(pool)
        end

        @pool = pool
      rescue
        Log.error("DB connection failed: #{$!}")
      end
    end
  end


  def self.ensure_tables_are_utf8(db)

    non_utf8_tables = db[:information_schema__tables].
      join(:information_schema__collation_character_set_applicability, :collation_name => :table_collation).
      filter(:table_schema => Sequel.function(:database)).
      filter(Sequel.~(:character_set_name => 'utf8')).all

    unless (non_utf8_tables.empty?)
      msg = <<EOF

The following MySQL database tables are not set to use UTF-8 for their character
encoding:

#{non_utf8_tables.map {|t| "  * " + t[:TABLE_NAME]}.join("\n")}

Please refer to README.md for instructions on configuring your database to use
UTF-8.

If you want to override this restriction (not recommended!) you can set the
following option in your config.rb file:

  AppConfig[:allow_non_utf8_mysql_database] = "true"

But note that ArchivesSpace largely assumes that your data will be UTF-8
encoded.  Running in a non-UTF-8 configuration is not supported.

EOF

      Log.warn(msg)
      raise msg
    end

    Log.info("All tables checked and confirmed set to UTF-8.  Nice job!")
  end


  def self.connected?
    not @pool.nil?
  end


  def self.transaction(*args)
    @pool.transaction(*args) do
      yield
    end
  end


  def self.after_commit(&block)
    if @pool.in_transaction?
      @pool.after_commit do
        block.call
      end
    else
      block.call
    end
  end


  def self.open(transaction = true, opts = {})
    last_err = false
    retries = opts[:retries] || 10

    retries.times do |attempt|
      begin
        if transaction
          self.transaction do
            return yield @pool
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


      rescue Sequel::DatabaseError => e
        if (attempt + 1) < retries && is_retriable_exception(e, opts) && transaction
          Log.info("Retrying transaction after retriable exception (#{e})")
          sleep(opts[:retry_delay] || 1)
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


  def self.needs_savepoint?
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


  def self.attempt(&block)
    DBAttempt.new(block)
  end


  # Yeesh.
  def self.is_integrity_violation(exception)
    (exception.wrapped_exception.cause or exception.wrapped_exception).getSQLState() =~ /^23/
  end


  def self.is_retriable_exception(exception, opts = {})
    # Transaction was rolled back, but we can retry
    (exception.instance_of?(RetryTransaction) ||
     (opts[:retry_on_optimistic_locking_fail] &&
      exception.instance_of?(Sequel::Plugins::OptimisticLocking::Error)) ||
     (exception.wrapped_exception.cause or exception.wrapped_exception).getSQLState() =~ /^(40|41)/)
  end


  def self.disconnect
    @pool.disconnect
  end


  def self.check_supported(url)
    if !SUPPORTED_DATABASES.any? {|db| url =~ db[:pattern]}

      msg = <<eof

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
      msg += <<eof

To ignore this (very good) advice, you can set the configuration option:

  AppConfig[:allow_unsupported_database] = true


=======================================================================

eof

      Log.error(msg)

      raise "Database not supported"
    end
  end


  def self.backups_dir
    AppConfig[:backup_directory]
  end


  def self.expire_backups

    backups = []
    Dir.foreach(backups_dir) do |filename|
      if filename =~ /^demo_db_backup_[0-9]+_[0-9]+$/
        backups << File.join(backups_dir, filename)
      end
    end

    victims = backups.sort.reverse.drop(AppConfig[:demo_db_backup_number_to_keep])

    victims.each do |backup_dir|
      # Proudly paranoid
      if File.exists?(File.join(backup_dir, "archivesspace_demo_db", "BACKUP.HISTORY"))
        Log.info("Expiring old backup: #{backup_dir}")
        FileUtils.rm_rf(backup_dir)
      else
        Log.warn("Too cowardly to delete: #{backup_dir}")
      end
    end
  end


  def self.demo_db_backup
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


  def self.increase_lock_version_or_fail(obj)
    updated_rows = obj.class.dataset.filter(:id => obj.id, :lock_version => obj.lock_version).
                       update(:lock_version => obj.lock_version + 1,
                              :system_mtime => Time.now)

    if updated_rows != 1
      raise Sequel::Plugins::OptimisticLocking::Error.new("Couldn't create version of: #{obj}")
    end
  end


  def self.supports_mvcc?
    ![:derby, :h2].include?(@pool.database_type)
  end


  def self.needs_blob_hack?
    (@pool.database_type == :derby)
  end

  def self.blobify(s)
    (@pool.database_type == :derby) ? s.to_sequel_blob : s
  end


  def self.concat(s1, s2)
    if @pool.database_type == :derby
      "#{s1} || #{s2}"
    else
      "CONCAT(#{s1}, #{s2})"
    end
  end

end
