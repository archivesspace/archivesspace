#!/bin/bash

which rlwrap &>/dev/null
if [ "$?" = 0 ]; then
  rlwrap=rlwrap
else
  rlwrap=""
fi

$rlwrap "`dirname $0`/jruby.sh" -e 'require "irb"; IRB.start()'
