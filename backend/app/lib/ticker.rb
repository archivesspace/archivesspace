# frozen_string_literal: true

class Ticker
  def initialize(job)
    @job = job
  end

  def tick; end

  def status_update(status_code, status)
    @job.write_output("#{status[:id]}. #{status_code.upcase}: #{status[:label]}")
  end

  def log(s)
    @job.write_output(s)
  end

  def tick_estimate=(n); end
end
