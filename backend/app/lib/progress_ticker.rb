require 'thread'
require 'atomic'

class ProgressTicker

  def initialize(opts = {}, &block)
    @frequency = opts[:frequency_seconds] || 5
    @ticks = 0

    @last_tick = Atomic.new(nil)
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
  end


  def tick(ticks = 1)
    @ticks += ticks
    @last_tick.update {|val| {:ticks => @ticks, :total => @estimated_total_ticks}}
  end


  def finished(args)
    @finished.update {|val| {:finished => args}}
    @tick_to_client_thread.join if @tick_to_client_thread
  end


  def each(&client)
    @tick_to_client_thread = Thread.new do
      while !@finished.value
        tick_for_client = @last_tick.value

        if tick_for_client
          client.call(ASUtils.to_json(tick_for_client) + "\n")
        end

        sleep @frequency
      end

      client.call(ASUtils.to_json(@finished.value))
    end

    # Start the computation
    begin
      @block.call(self)
    ensure
      finished if !@finished.value
      @tick_to_client_thread.join
    end
  end
end
