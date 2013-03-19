#!/bin/bash

cd "`dirname $0`"

export GEM_HOME="../gems"
export GEM_PATH=

java -cp "../gems/gems/jruby-jars-1.7.0/lib/*:../lib/*" org.jruby.Main --1.9 ../scripts/rb/migrate_db.rb


