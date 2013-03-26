#!/bin/bash

export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/find-base.sh)"

cd "$ASPACE_LAUNCHER_BASE/scripts"

export GEM_HOME="../gems"
export GEM_PATH=

java $JAVA_OPTS -cp "../gems/gems/jruby-jars-1.7.0/lib/*:../lib/*" org.jruby.Main --1.9 ../scripts/rb/migrate_db.rb
