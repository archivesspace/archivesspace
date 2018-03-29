require 'ashttp'
require "uri"
require "json"
require "digest"
require "rspec"
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'

require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'
require_relative '../../indexer/app/lib/pui_indexer'

require_relative '../../selenium/common/backend_client_mixin'
module BackendClientMethods
  alias :run_all_indexers_orig :run_all_indexers
  # patch this to also run our PUI indexer.
  def run_all_indexers
    run_all_indexers_orig
    $pui.run_index_round
  end
end

# IF we want simplecov reports
if ENV['COVERAGE_REPORTS'] == 'true'
  require 'simplecov'
  SimpleCov.start('rails') do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
end 

require 'aspace_gems'

# This defines how we startup the Backend and Solr. It's called by rspec in the
# before(:suite) block
$server_pids = []
$backend_port = TestUtils::free_port_from(3636)
$frontend_port = TestUtils::free_port_from(4545)
$solr_port = TestUtils::free_port_from(2989)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 30000
  
AppConfig[:backend_url] = $backend
AppConfig[:solr_url] = "http://localhost:#{$solr_port}"

$backend_start_fn = proc {
    
  # for the indexers
  TestUtils::start_backend($backend_port,
                           {
                             :solr_port => $solr_port,
                             :session_expire_after_seconds => $expire,
                             :realtime_index_backlog_ms => 600000
                           })
}


ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)                                                                                                                            
require 'rspec/rails'
include FactoryBot::Syntax::Methods

RSpec.configure do |config|
  
  config.include FactoryBot::Syntax::Methods
  config.include BackendClientMethods
  
  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.before(:suite) do 
    puts "Starting backend using #{$backend}"
    $server_pids << $backend_start_fn.call
    ArchivesSpaceClient.init 
    $admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    if !ENV['ASPACE_INDEXER_URL']
      $indexer = RealtimeIndexer.new($backend, nil)
      $period = PeriodicIndexer.new($backend, nil, "periodic_indexer", false)
      $pui = PUIIndexer.new($backend, nil, "pui_periodic_indexer")
    end
    FactoryBot.reload 
    AspaceFactories.init
     
  end

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils::kill(pid)
    end
  end

end

