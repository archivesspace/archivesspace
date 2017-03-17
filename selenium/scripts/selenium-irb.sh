#!/bin/bash

cd "`dirname $0`"

rlwrap="`which rlwrap 2>/dev/null`"



GEM_HOME=$PWD/../../build/gems $rlwrap java -cp ../../build/jruby-complete-*.jar org.jruby.Main \
    -I "../spec/" -I "../../common" -r spec_helper.rb -r irb -e '
selenium_init($backend_start_fn, $frontend_start_fn)

class Fixnum
  def to_str
    self.to_s
  end
end

class Object
  def method_missing(*stuff)
    self
  end
end

def it(*stuff)
  yield
end

class IRB::Locale

  private
  def real_load(path, priv)
    begin 
      src = IRB::MagicFile.open(path){|f| f.read}
      
      if priv
        eval("self", TOPLEVEL_BINDING).extend(Module.new {eval(src, nil, path)})
      else
        eval(src, TOPLEVEL_BINDING, path)
      end
    rescue Exception
      $stderr.puts "burrp" 
      $stderr.puts path
    end
  end

end

IRB.start()'
