#!/bin/bash

tomcat="`cd "$1"; pwd`"

java -cp "../gems/gems/jruby-jars-1.7.0/lib/*:../lib/*" org.jruby.Main --1.9 ../launcher/tomcat/lib/configure-tomcat.rb "$tomcat"


