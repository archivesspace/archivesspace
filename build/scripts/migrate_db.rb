require 'logger'
require 'active_support/inflector'

if $0 =~ /scripts[\/\\]rb[\/\\]migrate_db.rb$/
  # This script runs in two contexts: build/run as a part of development, and
  # setup-database.(sh|bat) from the distribution zip file.  Allow for both.
  require_relative '../../launcher/launcher_init'
end

require 'config/config-distribution'
require "db/db_migrator"

if AppConfig[:db_url] =~ /jdbc:mysql/
  require "db/sequel_mysql_timezone_workaround"
end


if ARGV.length > 0 and ARGV[0] == "nuke"
  if (AppConfig[:db_url] =~ /jdbc:derby:(.*?);.*aspacedemo=true$/)
    dir = $1

    if File.directory?(dir) and File.exist?(File.join(dir, "seg0"))
      puts "Nuking demo database: #{dir}"
      sleep(5)
      FileUtils.rm_rf(dir)
      exit
    end
  end
end


begin
  migration_logger = Logger.new($stderr)

  # Just log messages relating to the migration.  Otherwise we get a full SQL
  # trace...
  def migration_logger.error(*args)
    unless args.to_s =~ /SCHEMA_INFO.*does not exist/
      super
    end
  end

  def migration_logger.info(*args)
    if args[0].is_a?(String) && args[0] =~ /applying migration/
      super
    end
  end

  Sequel.connect(AppConfig[:db_url],
                 :max_connections => 1,
                 :loggers => [migration_logger]) do |db|
    if ARGV.length > 0 and ARGV[0] == "nuke"
      DBMigrator.nuke_database(db)

      indexer_state = File.join(AppConfig[:data_directory], "indexer_state")
      if Dir.exist? (indexer_state)
        FileUtils.rm_rf(indexer_state)
      end
    else
      puts "Running migrations against #{AppConfig[:db_url_redacted]}"
      DBMigrator.setup_database(db)
      puts "All done."
    end
  end
rescue Sequel::AdapterNotFound => e

  if AppConfig[:db_url] =~ /mysql/
    libdir = File.expand_path(File.join(File.dirname($0), "..", "..", "lib"))

    puts <<EOF

You have configured ArchivesSpace to use MySQL but seem to be missing the MySQL
JDBC driver (#{e}).

Please download the latest version of 'mysql-connector-java-X.Y.Z.jar' and place
it in the following directory:

  #{libdir}

You can find the latest version at the following URL:

  http://mvnrepository.com/artifact/mysql/mysql-connector-java/

Once you have installed the MySQL connector, please re-run this script.

EOF
  else
    raise $!
  end
end
