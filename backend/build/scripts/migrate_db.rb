require_relative File.join("..", "..", "app", "main")

Sequel.connect(AppConfig::DB_URL,
               :max_connections => AppConfig::DB_MAX_CONNECTIONS) do |db|
  puts "Running migrations..."
  DBMigrator.setup_database(db)
  puts "All done."
end
