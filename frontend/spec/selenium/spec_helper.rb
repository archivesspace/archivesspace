# frozen_string_literal: true
require 'factory_bot'
require_relative 'common'
require_relative '../../../indexer/app/lib/realtime_indexer'
require_relative '../../../indexer/app/lib/periodic_indexer'
require_relative '../../../indexer/app/lib/pui_indexer'

$backend_port = TestUtils.free_port_from(3636)
$frontend_port = TestUtils.free_port_from(4545)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 30_000

$backend_start_fn = proc {
  pid = TestUtils.start_backend($backend_port,
                                frontend_url: $frontend,
                                session_expire_after_seconds: $expire,
                                realtime_index_backlog_ms: 600_000,
                                db_url: AppConfig[:db_url])

  AppConfig[:backend_url] = $backend

  pid
}

$frontend_start_fn = proc {
  pid = TestUtils.start_frontend($frontend_port, $backend)

  pid
}

include FactoryBot::Syntax::Methods

RSpec.configure do |config|
  config.fail_fast = false

  config.expect_with(:rspec) do |c|
    c.syntax = %i[should expect]
  end

  config.include BackendClientMethods
  config.include TreeHelperMethods
  config.include FactoryBot::Syntax::Methods
  config.verbose_retry = true

  config.before(:suite) do
    selenium_init($backend_start_fn, $frontend_start_fn)
    $admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    JSONModel.init(client_mode: true,
                   url: AppConfig[:backend_url],
                   priority: :high)

    require_relative 'factories'
    SeleniumFactories.init
    # runs indexers in the same thread as the tests
    $indexer = RealtimeIndexer.new($backend, nil)
    $period = PeriodicIndexer.new($backend, nil, 'periodic_indexer', false)
  end

  config.after(:suite) do
    report_sleep
    cleanup
  end

  config.before(:all) do
    Dir.glob(File.join(Dir.tmpdir, '*.{csv, pdf,xml}')).each do |file|
      cmd = "rm #{file}"
      `#{cmd}`
    end
  end

  # Run each example, saving a screenshot on any sort of failure
  config.around(:each) do |example|
    example.run
    if example.exception || example.execution_result.status == :failed
      if example.exception
        puts "ERROR: Caught exception in example: #{example.exception}"
        puts Array(example.exception.backtrace).join("\n    ")
      end
    end
  end
end
