#!/bin/bash

plugin="$1"

if [ "$plugin" = "" ]; then
  echo "Usage: $0 <plugin name>"
  exit 1
fi

# We'll provide our own values for these
unset GEM_HOME
unset GEM_PATH

export ASPACE_LAUNCHER_BASE="$("$(dirname $0)"/find-base.sh)"

export JRUBY=
for dir in "$ASPACE_LAUNCHER_BASE"/gems/gems/jruby-*; do
  JRUBY="$JRUBY:$dir/lib/*"
done

export ASPACE_JRUBY_CLASSPATH="$ASPACE_LAUNCHER_BASE/lib/*$JRUBY"
export ASPACE_JAVA_OPTS="$JAVA_OPTS"

java $JAVA_OPTS -cp "$ASPACE_JRUBY_CLASSPATH" \
  org.jruby.Main "$ASPACE_LAUNCHER_BASE/scripts/rb/initialize_plugin.rb" "$plugin"
