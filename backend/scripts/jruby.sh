#!/bin/bash

base="`dirname $0`"

export GEM_HOME="$base/../.bootstrap"

java -cp "$base/../lib/*" org.jruby.Main --1.9 ${1+"$@"}
