#!/bin/bash

base="`dirname $0`"

JRUBY_OPTS=""
export JRUBY_OPTS

export RUBYLIB=$base/../app/lib:$RUBYLIB

jruby $base/../build/scripts/migrate_db.rb
