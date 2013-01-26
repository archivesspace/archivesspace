require 'thread'

class RealtimeIndexing

  def self.reset!
    @lock.synchronize do
      @updates = []
    end
  end


  def self.record_delete(uri)
    record_update(:deleted, uri)
  end


  def self.record_update(target, uri)
    @lock.synchronize do
      @sequence += 1
      now = (Time.now.to_f * 1000).to_i
      @updates << {
        :sequence => @sequence,
        :uri => uri,
        :record => target,
        :timestamp => now
      }

      expire_older_than(now - AppConfig[:realtime_index_backlog_ms])

      # Wake up any threads waiting for updates
      @waiting_list.broadcast
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
        # Block until an update wakes us up (or until we time out)
        @waiting_list.wait(@lock, AppConfig[:realtime_index_backlog_ms] / 1000)
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

  def self.expire_older_than(timestamp)
    @updates = @updates.reject {|elt| elt[:timestamp] <= timestamp}
  end


  @lock = Mutex.new
  @waiting_list = ConditionVariable.new
  @sequence = Time.now.to_i
  @updates = []
end
