#!/bin/bash

tomcat="`cd "$1"; pwd`"

export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/find-base.sh)"

cd "$ASPACE_LAUNCHER_BASE/scripts"

export JRUBY=
for dir in ../gems/gems/jruby-*; do
    JRUBY="$JRUBY:$dir/lib/*"
done

export GEM_PATH="../gems"

echo $JRUBY
java $JAVA_OPTS -cp "../lib/*$JRUBY" org.jruby.Main --1.9 ../launcher/tomcat/lib/configure-tomcat.rb "$tomcat"


