require 'thread'

class LongPolling

  def initialize(ms_to_keep)
    @lock = Mutex.new
    @waiting_list = ConditionVariable.new
    @sequence = Time.now.to_i
    @updates = []
    @ms_to_keep = ms_to_keep
  end


  def shutdown
    @lock.synchronize do
      @waiting_list.broadcast
    end
  end

  def reset!
    @lock.synchronize do
      @updates = []
    end
  end


  def record_update(values)
    @lock.synchronize do
      @sequence += 1
      now = (Time.now.to_f * 1000).to_i
      @updates << values.merge(:sequence => @sequence,
                               :timestamp => now)

      expire_older_than(now - @ms_to_keep)

      # Wake up any threads waiting for updates
      @waiting_list.broadcast
    end
  end


  def updates_since(seq)
    @lock.synchronize do
      updates_after(seq)
    end
  end


  def blocking_updates_since(seq)
    @lock.synchronize do
      updates = updates_after(seq)

      if updates.empty?
        # Block until an update wakes us up (or until we time out)
        @waiting_list.wait(@lock, @ms_to_keep / 1000.0)
        updates_after(seq)
      else
        updates
      end
    end
  end


  private

  def updates_after(seq)
    @updates.drop_while {|entry| entry[:sequence] <= seq}
  end


  def expire_older_than(timestamp)
    @updates = @updates.reject {|elt| elt[:timestamp] <= timestamp}
  end

end
