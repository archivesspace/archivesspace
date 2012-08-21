#!/bin/bash

base="`dirname $0`"

JRUBY_OPTS="--1.9"
export JRUBY_OPTS

export RUBYLIB=$base/../app/lib:$RUBYLIB

echo $1

jruby $base/../scripts/migrate_db.rb $1