#!/bin/bash

plugin="$1"

export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/find-base.sh)"

cd "$ASPACE_LAUNCHER_BASE/plugins/$plugin"

if [ "$plugin" = "" ]; then
    echo "Usage: $0 <plugin name>"
    exit
fi

if [ "$?" != "0" ]; then
    echo "Failed to find plugin: $plugin"
    exit
fi

export JRUBY=
for dir in ../../gems/gems/jruby-*; do
    JRUBY="$JRUBY:$dir/lib/*"
done

export GEM_HOME=gems

java $JAVA_OPTS -cp "../../lib/*$JRUBY" org.jruby.Main --1.9 -S gem install bundler
java $JAVA_OPTS -cp "../../lib/*$JRUBY" org.jruby.Main --1.9 ../../gems/bin/bundle install --gemfile=Gemfile


