#!/bin/bash

export ORIG_PWD="$PWD"
export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/find-base.sh)"

cd "$ASPACE_LAUNCHER_BASE/scripts"

export GEM_HOME="$PWD/../gems"
export GEM_PATH=

export JRUBY=
for dir in ../gems/gems/jruby-*; do
    JRUBY="$JRUBY:$dir/lib/*"
done


java $JAVA_OPTS -cp "../lib/*$JRUBY" org.jruby.Main --1.9 ../launcher/backup/lib/backup.rb ${1+"$@"}
