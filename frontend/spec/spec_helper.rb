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
require 'axe-rspec'
require 'jsonmodel'
require 'aspace_logger'

require_relative '../../indexer/app/lib/pui_indexer'
require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('frontend:test', 'rails')
end
AppConfig[:frontend_cookie_secret] = "shhhhh"
AppConfig[:enable_custom_reports] = true
app_logfile = File.join(ASUtils.find_base_directory, "ci_logs", "frontend_app_log.out")
AppConfig[:frontend_log] = app_logfile

backend_port = TestUtils.free_port_from(3636)
$backend = ENV['ASPACE_TEST_BACKEND_URL'] || "http://localhost:#{backend_port}"
test_db_url = ENV['ASPACE_TEST_DB_URL'] || AppConfig[:db_url]
AppConfig[:backend_url] = $backend

$logger = ASpaceLogger.new(File.join(ASUtils.find_base_directory, "ci_logs", "frontend_test_log.out"))
$logger.level = :debug

require 'factory_bot'
include FactoryBot::Syntax::Methods
include TestUtils::SpecIndexing::Methods

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
    if ENV['ASPACE_TEST_BACKEND_URL']
      puts "Running tests against #{AppConfig[:backend_url]}"
    else
      puts "Starting backend #{AppConfig[:backend_url]}"
      $server_pids << TestUtils.start_backend(backend_port,
                                              session_expire_after_seconds: 6000000000,
                                              realtime_index_backlog_ms: 600000,
                                              db_url: test_db_url
                                             )
    end

    JSONModel::init(:client_mode => true,
                    :url => AppConfig[:backend_url],
                    :priority => :high)

    require_relative 'factories'

    $indexer = RealtimeIndexer.new(AppConfig[:backend_url], nil)
    $period = PeriodicIndexer.new($backend, nil, 'periodic_indexer', false)

    Factories.init
    $repo = create(:repo, :repo_code => "test_#{Time.now.to_i}", publish: true)
    set_repo $repo
    create(:accession)
    create(:resource)
    run_indexer
  end

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils.kill(pid)
    end
    begin
      $puma.halt
    rescue
      # we do not care about exceptions while shutting down puma at this point
    end
  end

  config.verbose_retry = true
  config.default_retry_count = ENV['ASPACE_TEST_RETRY_COUNT'] || 1
  config.fail_fast = false
end
