#!/bin/bash

set -e

base="`dirname $0`"

cd "$base"/../

mkdir -p "lib"
(
    cd lib
    wget -c "http://jruby.org.s3.amazonaws.com/downloads/1.6.7.2/jruby-complete-1.6.7.2.jar"
)

if [ ! -d ".bootstrap" ] || [ "Gemfile" -nt ".bootstrap" ] ; then
    export GEM_HOME=".bootstrap"
    $base/jruby.sh -S gem install bundler

    $base/jruby.sh .bootstrap/bin/bundle

    touch .bootstrap
fi
