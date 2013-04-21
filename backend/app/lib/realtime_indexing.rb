require_relative 'longpolling'

class RealtimeIndexing

  def self.longpolling
    if !@longpolling
      @longpolling = LongPolling.new(AppConfig[:realtime_index_backlog_ms].to_i)
    end

    @longpolling
  end


  def self.shutdown
    @longpolling.shutdown if @longpolling
  end


  def self.reset!
    longpolling.reset!
  end


  def self.record_update(target, uri)
    longpolling.record_update(:record => target, :uri => uri)
  end


  def self.record_delete(uri)
    longpolling.record_update(:record => :deleted, :uri => uri)
  end


  def self.updates_since(seq)
    longpolling.updates_since(seq)
  end


  def self.blocking_updates_since(seq)
    longpolling.blocking_updates_since(seq)
  end

end
