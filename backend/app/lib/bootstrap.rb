require 'rubygems'
require 'sequel'

require_relative 'exceptions'
require_relative 'logging'

if File.exists?(File.join("..", "..", "config", "config.rb"))
  require_relative File.join("..", "..", "config", "config")
else
  require_relative File.join("..", "..", "config", "config-distribution")
end

require_relative File.join("..", "..", "..", "common", "jsonmodel")
JSONModel::init

require_relative File.join("..", "model", "db_migrator")

if not Thread.current[:test_mode]
  if AppConfig::DB_URL =~ /aspacedemo=true/
    puts "Running database migrations for demo database"

    Sequel.connect(AppConfig::DB_URL) do |db|
      DBMigrator.setup_database(db)
    end

    puts "All done."
  end
end
