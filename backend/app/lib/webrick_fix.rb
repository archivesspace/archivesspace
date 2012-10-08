require 'webrick'

# Work around this very transient issue:
#
# [2012-10-07 15:54:12] ERROR RuntimeError: can't add a new key into hash during iteration
#         org/jruby/RubyHash.java:905:in `[]='
#         jar:file:/mnt/ssd/archivesspace/build/jruby-complete-1.7.0.RC1.jar!/META-INF/jruby.home/lib/ruby/1.9/webrick/utils.rb:205:in `register'
#         jar:file:/mnt/ssd/archivesspace/build/jruby-complete-1.7.0.RC1.jar!/META-INF/jruby.home/lib/ruby/1.9/webrick/utils.rb:161:in `register'


module WEBrick
  module Utils
    class TimeoutHandler
      def initialize
        @timeout_info = Hash.new
        Thread.start{
          while true
            now = Time.now
            @timeout_info.keys.each{|thread|
              ary = @timeout_info[thread]
              next unless ary
              ary.dup.each{|info|
                time, exception = *info
                interrupt(thread, info.object_id, exception) if time < now
              }
            }
            sleep 0.5
          end
        }
      end
    end
  end
end
