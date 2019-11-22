#!/usr/bin/env ruby

require 'sequel'
require 'securerandom'

Thread.abort_on_exception = true

# Run a piece of code across a pool of threads with a bounded queue.  Use like this:
#
# pool = PooledExecutor.new(threads: 10, queue_size: 32) do |db, work|
#   do_something(db, work)
# end
#
# pool.submit("some parameter") # This parameter assigned to `work` in the
#                               # block above and executed on a thread.
#
# pool.shutdown  # Wait for them all to finish & shut down worker threads
#
# If a worker thread throws an exception, the whole pool aborts and raises an
# exception with the caller.
#
# `db` is a Sequel database connection run with a transaction established for
# that worker thread.

class PooledExecutor
  def initialize(thread_count:, queue_size:, request_context:, &block)
    @queue = java.util.concurrent.ArrayBlockingQueue.new(queue_size)
    @pool_status = java.util.concurrent.atomic.AtomicReference.new(:running)

    @threads = thread_count.times.map do |id|
      Thread.new do
        begin
          Thread.current.name = "PooledExecutor::worker_#{id}"
          RequestContext.open(request_context) do
            DB.open(false) do |db|
              # If something has failed, abort straight away
              while @pool_status.get != :failed
                work = @queue.poll(1, java.util.concurrent.TimeUnit::SECONDS)
                if work
                  # If we got some work to do, er, do it.
                  block.call(db, work[0])
                else
                  # Nothing on the queue, and we're shutting down.  All done.
                  break if @pool_status.get == :shutdown
                end
              end
            end
          end
        rescue
          $stderr.puts("PooledExecutor error caught: #{$!}")
          $stderr.puts($@.join("\n"))
          @pool_status.set(:failed)
        end
      end
    end

    def submit(work)
      # Wrap work in an array so we know that @queue.poll will never
      # legitimately return a nil.
      while !@queue.offer([work], 1, java.util.concurrent.TimeUnit::SECONDS)
        if @pool_status.get == :shutdown
          raise "PooledExecutor: Pool is shut down"
        elsif @pool_status.get == :failed
          raise "PooledExecutor: Error during processing"
        end
      end
    end

    def shutdown
      if @pool_status.get == :failed
        raise "PooledExecutor: Error during processing"
      else
        @pool_status.set(:shutdown)
      end

      @threads.each(&:join)
    end
  end
end
