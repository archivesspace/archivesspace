#!/bin/bash

plugin="$1"

# We'll provide our own values for these
unset GEM_HOME
unset GEM_PATH

export ASPACE_LAUNCHER_BASE="$("`dirname $0`"/find-base.sh)"

cd "$ASPACE_LAUNCHER_BASE/gems/gems"
BUNDLER_VERSION=$(ls | grep bundler | cut -d'-' -f 2)

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

java $JAVA_OPTS -cp "../../lib/*$JRUBY" org.jruby.Main --1.9 -S gem install bundler -v "$BUNDLER_VERSION"
java $JAVA_OPTS -cp "../../lib/*$JRUBY" org.jruby.Main --1.9 ../../gems/bin/bundle install --gemfile=Gemfile


