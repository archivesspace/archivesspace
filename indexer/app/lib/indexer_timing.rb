class IndexerTiming
  def initialize
    @metrics = {}
  end

  def add(metric, val)
    @metrics[metric] ||= 0
    @metrics[metric] += val.to_i
  end

  def to_s
    subtotal = @metrics.values.inject(0) {|a, b| a + b}

    if @total
      # If we have a total, report any difference between the total and the
      # numbers we have.
      add(:other, @total - subtotal)
    else
      # Otherwise, just tally up our numbers to determine the total.
      @total = subtotal
    end

    "#{@total.to_i} ms (#{@metrics.map {|k, v| "#{k}: #{v}"}.join('; ')})"
  end

  def total=(ms)
    @total = ms
  end

  def time_block(metric)
    start_time = Time.now
    begin
      yield
    ensure
      add(metric, ((Time.now.to_f * 1000) - (start_time.to_f * 1000)))
    end
  end
end
