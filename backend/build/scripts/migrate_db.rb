require_relative File.join("..", "..", "app", "main")

Sequel.connect(AppConfig[:db_url],
               :max_connections => AppConfig[:db_max_connections],
               # :loggers => [Logger.new($stderr)]
               ) do |db|
  if ARGV.length > 0 and ARGV[0] == "nuke"
    puts "Nuking database"
    DBMigrator.nuke_database(db)
  end

  puts "Running migrations..."
  DBMigrator.setup_database(db)
  puts "All done."
end
