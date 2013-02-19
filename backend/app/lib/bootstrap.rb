require 'rubygems'
require 'sequel'
require 'sequel/plugins/optimistic_locking'
Sequel.extension :pagination

require 'fileutils'
require_relative 'exceptions'
require_relative 'logging'
require_relative "../../../config/config-distribution"
require_relative "../../../common/jsonmodel"
require_relative "../../../common/asutils"
require_relative "../model/db_migrator"
require_relative 'webhooks'
require_relative 'username'


if ENV["ASPACE_INTEGRATION"] == "true"
  AppConfig[:db_url] = "jdbc:derby:memory:integrationdb;create=true;aspacedemo=true"
end

if not Thread.current[:test_mode]
  FileUtils.mkdir_p(AppConfig[:data_directory])

  if AppConfig[:db_url] =~ /aspacedemo=true/
    puts "Running database migrations for demo database"

    Sequel.connect(AppConfig[:db_url]) do |db|
      DBMigrator.setup_database(db)
    end

    puts "All done."
  end
end
