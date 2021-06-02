# frozen_string_literal: true

require 'ashttp'
require 'uri'
require 'json'
require 'digest'
require 'rspec'
require 'rspec/retry'
require 'rspec-benchmark'
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'
require 'nokogiri'


if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('frontend:test', 'rails')
end
AppConfig[:frontend_cookie_secret] = "shhhhh"

backend_port = TestUtils.free_port_from(3636)
AppConfig[:backend_url] = "http://localhost:#{backend_port}"

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include RSpec::Benchmark::Matchers

  config.before(:suite) do
    $server_pids = []
    $server_pids << TestUtils.start_backend(backend_port,
                                            session_expire_after_seconds: 6000000000,
                                            realtime_index_backlog_ms: 600000,
                                            db_url: AppConfig[:db_url]
                                           )
  end

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils.kill(pid)
    end
    # For some reason we have to manually shutdown mizuno for the test suite to
    # quit.
    Rack::Handler.get('mizuno').instance_variable_get(:@server) ? Rack::Handler.get('mizuno').instance_variable_get(:@server).stop : next
  end
end
