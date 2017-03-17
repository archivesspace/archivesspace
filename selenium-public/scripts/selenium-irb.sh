#!/bin/bash

cd "`dirname $0`"

rlwrap="`which rlwrap 2>/dev/null`"



GEM_HOME=$PWD/../../build/gems $rlwrap java -cp ../../build/jruby-complete-*.jar org.jruby.Main \
    -I "../spec/" -r spec_helper.rb -r irb -e '
selenium_init

class Object
  def method_missing(*stuff)
    self
  end
end

def it(*stuff)
  yield
end

IRB.start()'
