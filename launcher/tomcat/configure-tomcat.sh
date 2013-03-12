#!/bin/bash

cd "`dirname $0`"

java -cp "gems/gems/jruby-jars-1.7.0/lib/*:lib/*" org.jruby.Main --1.9 launcher/tomcat/lib/configure-tomcat.rb ${1+"$@"}


