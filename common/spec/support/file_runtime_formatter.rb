# spec/support/file_runtime_formatter.rb
require "rspec/core/formatters"

class FileRuntimeFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_finished, :dump_summary, :start

  def initialize(output)
    @output = output
    @file_runtimes = Hash.new(0.0)
    @example_starts = {}
    @top_n = (ENV["SLOW_FILES"] || 10).to_i  # default 10 slowest files
  end

  def start(_notification)
    @suite_start = current_time
  end

  def example_started(notification)
    @example_starts[notification.example.id] = current_time
  end

  def example_finished(notification)
    started = @example_starts.delete(notification.example.id)
    runtime = current_time - started
    file = notification.example.metadata[:file_path]
    @file_runtimes[file] += runtime
  end

  def dump_summary(_summary)
    total_runtime = current_time - @suite_start

    @output.puts "\n\n== Spec runtime summary =="
    @output.puts "Total suite runtime: #{format_time(total_runtime)}"

    sorted = @file_runtimes.sort_by { |_, time| -time }.first(@top_n)
    @output.puts "\nSlowest #{@top_n} spec files:"
    sorted.each do |file, time|
      @output.puts "  #{file}: #{format_time(time)}"
    end
  end

  private

  def current_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def format_time(seconds)
    minutes = (seconds / 60).to_i
    secs = (seconds % 60).round(2)
    if minutes > 0
      "#{minutes}m #{secs}s"
    else
      "#{secs}s"
    end
  end
end
