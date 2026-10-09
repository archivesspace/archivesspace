# RSpec formatter that records how long each spec file takes to run, used to
# balance the frontend feature spec shards (see ../frontend_feature_shards.rb).
#
# It measures each top level example group from start to finish, so the time
# includes before(:all)/after(:all) hooks, and writes one JSON line per group:
#
#   {"run":"<id of this rspec run>","file":"spec/features/x_spec.rb","seconds":12.3}
#
# Lines are appended and flushed as groups finish, so an interrupted run still
# leaves the timings of the files that completed.
require 'json'
require 'securerandom'

class FileTimingFormatter
  RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished

  def initialize(output)
    @output = output
    @run = SecureRandom.hex(8)
    @started_at = {}
  end

  def example_group_started(notification)
    group = notification.group
    @started_at[group] = now if group.top_level?
  end

  def example_group_finished(notification)
    group = notification.group
    return unless group.top_level?

    seconds = now - @started_at.delete(group)
    file = group.metadata[:file_path].sub(%r{\A\./}, '')
    @output.puts({ run: @run, file: file, seconds: seconds.round(2) }.to_json)
    @output.flush
  end

  private

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
