require 'rubygems'
require 'sequel'

require_relative 'exceptions'
require_relative 'logging'
require_relative File.join("..", "..", "config", "config-distribution")

if File.file?(File.join("config", "config.rb"))
  require_relative File.join("..", "..", "config", "config")
end


require_relative File.join("..", "..", "..", "common", "jsonmodel")
JSONModel::init

require_relative File.join("..", "model", "db_migrator")

if ENV["ASPACE_INTEGRATION"] == "true"
  AppConfig[:db_url] = "jdbc:derby:memory:integrationdb;create=true;aspacedemo=true"
end

if not Thread.current[:test_mode]
  if AppConfig[:db_url] =~ /aspacedemo=true/
    puts "Running database migrations for demo database"

    Sequel.connect(AppConfig[:db_url]) do |db|
      DBMigrator.setup_database(db)
    end

    puts "All done."
  end
end
