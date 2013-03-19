#!/bin/bash

tomcat="`cd "$1"; pwd`"

java $JAVA_OPTS -cp "../gems/gems/jruby-jars-1.7.0/lib/*:../lib/*" org.jruby.Main --1.9 ../launcher/tomcat/lib/configure-tomcat.rb "$tomcat"


