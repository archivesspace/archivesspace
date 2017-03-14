require_relative '../../selenium/spec/factories'
require_relative "../../selenium/common"
require_relative '../../indexer/app/lib/periodic_indexer'
require_relative '../../indexer/app/lib/pui_indexer'


$backend_port = TestUtils::free_port_from(3636)
$public_port = TestUtils::free_port_from(4546)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$public_port}"
$expire = 300

$backend_start_fn = proc {
  TestUtils::start_backend($backend_port,
                           {
                             :frontend_url => $frontend,
                             :session_expire_after_seconds => $expire
                           })
}

$frontend_start_fn = proc {
  TestUtils::start_public($public_port, $backend)
}

RSpec.configure do |config|
  config.include BackendClientMethods
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    selenium_init($backend_start_fn, $frontend_start_fn)
    SeleniumFactories.init
    $indexer = PeriodicIndexer.new($backend, nil, 'Periodic')
    $pui_indexer = PUIIndexer.new($backend, nil, 'PUI')
  end

  if ENV['ASPACE_TEST_WITH_PRY']
    require 'pry'
    config.around(:each) do |example|
      example.run
      if example.exception
        puts "FAILED: #{example.exception}"
        binding.pry
      end
    end
  end

end

def run_index_round
  $indexer.run_index_round
  $pui_indexer.run_index_round
end
