if $0 =~ /scripts\/rb\/migrate_db\.rb$/
  # This script runs in two contexts: build/run as a part of development, and
  # setup-database.(sh|bat) from the distribution zip file.  Allow for both.
  require_relative '../../launcher/launcher_init'
end

require 'config/config-distribution'
require "db/db_migrator"


if ARGV.length > 0 and ARGV[0] == "nuke"
  if (AppConfig[:db_url] =~ /jdbc:derby:(.*?);.*aspacedemo=true$/)
    dir = $1

    if File.directory?(dir) and File.exists?(File.join(dir, "seg0"))
      puts "Nuking demo database: #{dir}"
      sleep(5)
      FileUtils.rm_rf(dir)
      exit
    end
  end
end


Sequel.connect(AppConfig[:db_url],
               :max_connections => AppConfig[:db_max_connections],
               # :loggers => [Logger.new($stderr)]
               ) do |db|
  if ARGV.length > 0 and ARGV[0] == "nuke"
    DBMigrator.nuke_database(db)

    indexer_state = File.join(AppConfig[:data_directory], "indexer_state")
    if Dir.exists? (indexer_state)
      FileUtils.rm_rf(indexer_state)
    end

  end

  puts "Running migrations against #{AppConfig[:db_url]}"
  DBMigrator.setup_database(db)
  puts "All done."
end
