require 'thread'

class RealtimeIndexing

  def self.reset!
    @lock.synchronize do
      @updates = []
    end
  end


  def self.record_update(obj)
    @lock.synchronize do
      @sequence += 1
      @updates << {
        :sequence => @sequence,
        :record => obj,
        :timestamp => (Time.now.to_f * 1000).to_i
      }

      # Wake up any threads waiting for updates
      @waiting_list.broadcast
    end
  end


  def self.expire_older_than(timestamp)
    @lock.synchronize do
      @updates = @updates.reject {|elt| elt[:timestamp] <= timestamp}
    end
  end


  def self.updates_since(seq)
    @lock.synchronize do
      updates_after(seq)
    end
  end


  def self.blocking_updates_since(seq)
    @lock.synchronize do
      updates = updates_after(seq)

      if updates.empty?
        # Block until an update wakes us up
        @waiting_list.wait(@lock)
        updates_after(seq)
      else
        updates
      end
    end
  end


  private

  def self.updates_after(seq)
    @updates.drop_while {|entry| entry[:sequence] <= seq}
  end


  @lock = Mutex.new
  @waiting_list = ConditionVariable.new
  @sequence = Time.now.to_i
  @updates = []
end
