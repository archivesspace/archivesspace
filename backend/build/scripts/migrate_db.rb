require_relative File.join("..", "..", "app", "main")

Sequel.connect(AppConfig::DB_URL,
               :max_connections => AppConfig::DB_MAX_CONNECTIONS,
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
