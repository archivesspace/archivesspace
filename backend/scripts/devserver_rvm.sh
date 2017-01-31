#!/bin/bash

base="`dirname $0`"

JRUBY_OPTS="--1.9"
export JRUBY_OPTS

export RUBYLIB=$base/../app/lib:$RUBYLIB

jruby $base/../app/main.rb