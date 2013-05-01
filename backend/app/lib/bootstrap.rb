require 'rubygems'
require 'java'
require 'sequel'
require 'sequel/plugins/optimistic_locking'
Sequel.extension :pagination

require "db/db_migrator"

require 'fileutils'
require "jsonmodel"
require "asutils"
require_relative 'exceptions'
require_relative 'logging'
require 'config/config-distribution'
require_relative 'username'


if ENV["ASPACE_INTEGRATION"] == "true"
  AppConfig[:db_url] = "jdbc:derby:memory:integrationdb;create=true;aspacedemo=true"
end

if not Thread.current[:test_mode]
  FileUtils.mkdir_p(AppConfig[:data_directory])

  if AppConfig[:db_url] =~ /aspacedemo=true/
    java.lang.System.set_property("derby.locks.escalationThreshold", "2147483647")
    puts "Running database migrations for demo database"

    Sequel.connect(AppConfig[:db_url]) do |db|
      DBMigrator.setup_database(db)
    end

    puts "All done."
  end
end
