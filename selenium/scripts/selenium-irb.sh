#!/bin/bash

cd "`dirname $0`"

rlwrap="`which rlwrap 2>/dev/null`"



GEM_HOME=$PWD/../../build/gems $rlwrap java -cp ../../build/jruby-complete-*.jar org.jruby.Main --1.9 \
    -I "../spec/" -I "../../common" -r spec_helper.rb -r irb -e '
selenium_init($backend_start_fn, $frontend_start_fn)

class Object
  def method_missing(*stuff)
    self
  end
end

def it(*stuff)
  yield
end

IRB.start()'
