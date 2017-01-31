#!/bin/bash

set -e

rvm install jruby

case "$GEM_HOME" in
  *jruby*)
    JRUBY_OPTS="--1.9" ; export JRUBY_OPTS
  ;;
esac

if ! command -v bundle ; then
  gem install bundler
fi

bundle

bundle show

