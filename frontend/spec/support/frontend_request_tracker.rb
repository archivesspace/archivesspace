# frozen_string_literal: true

# Counts the requests the in-process test server is handling, so a spec can
# wait until every request the page has sent (fetch and jQuery alike) has
# been answered.  wait_for_ajax only sees jQuery requests, and only after a
# fixed sleep.
class FrontendRequestTracker
  @in_flight = 0
  @lock = Mutex.new

  class << self
    def idle?
      @lock.synchronize { @in_flight.zero? }
    end

    def track
      @lock.synchronize { @in_flight += 1 }
      yield
    ensure
      @lock.synchronize { @in_flight -= 1 }
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    self.class.track { @app.call(env) }
  end
end

Capybara.app = FrontendRequestTracker.new(Capybara.app)

module FrontendRequestTrackerHelpers
  # Waits until the server has had no request in progress for `quiet`
  # seconds.  The quiet period covers a request the browser has started but
  # not yet sent, and a response still on its way to the page.
  def wait_for_frontend_requests(quiet: 0.25)
    Timeout.timeout(Capybara.default_max_wait_time) do
      idle_since = nil
      loop do
        if FrontendRequestTracker.idle?
          idle_since ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)
          break if Process.clock_gettime(Process::CLOCK_MONOTONIC) - idle_since >= quiet
        else
          idle_since = nil
        end
        sleep 0.05
      end
    end
  end
end

RSpec.configure do |config|
  config.include FrontendRequestTrackerHelpers, type: :feature
end
