#!/bin/bash

tomcat="`cd "$1"; pwd`"

export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/find-base.sh)"

cd "$ASPACE_LAUNCHER_BASE/scripts"

java $JAVA_OPTS -cp "../gems/gems/jruby-jars-1.7.0/lib/*:../lib/*" org.jruby.Main --1.9 ../launcher/tomcat/lib/configure-tomcat.rb "$tomcat"


