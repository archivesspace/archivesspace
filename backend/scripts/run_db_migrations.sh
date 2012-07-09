#!/bin/bash

cd "`dirname $0`/../"

cat <<EOF | scripts/jruby.sh -Iapp
require "bootstrap"
require "model/db_migrator"

Sequel.connect(AppConfig::DB_URL,
               :max_connections => AppConfig::DB_MAX_CONNECTIONS) do |db|
    puts "Running migrations..."
    DBMigrator.setup_database(db)
    puts "All done."
end

EOF
    


