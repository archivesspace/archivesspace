require 'ashttp'
require "uri"
require "json"
require "digest"
require "rspec"
require 'rspec/retry'
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'
require 'axe/rspec'
require 'nokogiri'

require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'
require_relative '../../indexer/app/lib/pui_indexer'

require_relative '../../common/selenium/backend_client_mixin'
module BackendClientMethods
  alias :run_all_indexers_orig :run_all_indexers
  # patch this to also run our PUI indexer.
  def run_all_indexers
    run_all_indexers_orig
    $pui.run_index_round
  end
end

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('public:test', 'rails')
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
                             :realtime_index_backlog_ms => 600000,
                             :db_url => ENV.fetch('ASPACE_TEST_DB_URL', AppConfig.demo_db_url)
                           })
}


ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
include FactoryBot::Syntax::Methods

def setup_test_data
  repo = create(:repo, :repo_code => "test_#{Time.now.to_i}", publish: true)
  set_repo repo
  create(:accession, title: "Published Accession")
  create(:accession, title: "Unpublished Accession", publish: false )
  create(:accession_with_deaccession, title: "Published Accession with Deaccession")
  create(:accession, title: "Accession for Phrase Search")

  resource = create(:resource, title: "Published Resource", publish: true)
  aos = (0..5).map do
    create(:archival_object,
           resource: { 'ref' => resource.uri }, publish: true)
  end
  unpublished_resource = create(:resource, title: "Unpublished Resource", publish: false)
  unp_aos = (0..5).map do
    create(:archival_object,
           resource: { 'ref' => unpublished_resource.uri }, publish: true)
  end
  create(:resource, title: "Resource for Phrase Search", publish: true)
  create(:resource, title: "Search as Phrase Resource", publish: true)

  resource_with_scope = create(:resource_with_scope, title: "Resource with scope note", publish: true)
  aos = (0..5).map do
    create(:archival_object,
           resource: { 'ref' => resource_with_scope.uri }, publish: true)
  end
  run_all_indexers
end

RSpec.configure do |config|

  config.include FactoryBot::Syntax::Methods
  config.include BackendClientMethods

  # show retry status in spec process
  config.verbose_retry = true
  # Try thrice (retry twice)
  config.default_retry_count = 3


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
    setup_test_data
  end

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils::kill(pid)
    end
    # For some reason we have to manually shutdown mizuno for the test suite to
    # quit.
    Rack::Handler.get('mizuno').instance_variable_get(:@server) ? Rack::Handler.get('mizuno').instance_variable_get(:@server).stop : next
  end

end
