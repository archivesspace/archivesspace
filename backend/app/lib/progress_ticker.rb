require 'thread'
require 'atomic'

class ProgressTicker

  def initialize(opts = {}, &block)
    @frequency = opts[:frequency_seconds] || 5
    @ticks = 0

    @last_tick = Atomic.new(nil)
    @status_updates = Atomic.new([])
    @results = Atomic.new({})
    @finished = Atomic.new(false)

    context = RequestContext.dump
    @block = proc {|ticker|
      RequestContext.open(context) do
        block.call(ticker)
      end
    }
  end


  def tick_estimate=(val)
    @estimated_total_ticks = val
    @ticks = 0
  end


  def tick(ticks = 1)
    @ticks += ticks
    @last_tick.update {|val| {:ticks => @ticks, :total => @estimated_total_ticks}}
    @ticks
  end


  def log(s)
    Log.debug(s)
  end

  def status_update(type, status)
    @status_updates.update{|val| val + [status.merge(:type => type)] }
  end
  
  
  def results=(result_hash)
    raise "bad argument: #{result_hash}" unless result_hash.is_a?(Hash)
    @results.update {|val| result_hash }
  end
  
  
  def results?
    return @results.value.empty? ? false : true
  end


  def finish!
    @finished.update {|val| true}
    @tick_to_client_thread.join if @tick_to_client_thread
  end
  
  
  def finished?
    @finished.value
  end


  def flush_statuses(client)
    updates = @status_updates.swap([])

    unless updates.empty?
      client.call(ASUtils.to_json(:status => updates) + ",\n")
    end
  end
  

  def flush_results(client)
    results = @results.swap({})
    
    unless results.empty?
      client.call(ASUtils.to_json(results) + "\n")
    end
  end
      

  def each(&client)
    @tick_to_client_thread = Thread.new do
      client.call("[\n")
      while !@finished.value
        tick_for_client = @last_tick.value

        flush_statuses(client)

        if tick_for_client
          client.call(ASUtils.to_json(tick_for_client) + ",\n")
        end

        sleep @frequency
      end

      flush_statuses(client)
      flush_results(client)
    end

    # Start the computation
    begin
      @block.call(self)
    ensure
      self.finish!
      client.call("\n]")
      @tick_to_client_thread.join
    end
  end
end
