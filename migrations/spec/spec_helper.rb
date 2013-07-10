require 'test_utils'
require 'config/config-distribution'
require 'I18n'

$test_mode = true

$backend_port = TestUtils::free_port_from(3636)
$backend_url = "http://localhost:#{$backend_port}"

$backend_start_fn = proc {
  TestUtils::start_backend($backend_port,
                           {
                             :session_expire_after_seconds => 300,
                             :realtime_index_backlog_ms => 600000,
                             :db_url => AppConfig.demo_db_url
                           })
}

AppConfig[:backend_url] = $backend_url

I18n.load_path += [File.join(File.dirname(__FILE__), "../", "../", "common", "locales", "enums", "#{AppConfig[:locale]}.yml")]

def start_backend
  $backend_pid = $backend_start_fn.call
  response = JSON.parse(`curl -F'password=admin' #{$backend_url}/users/admin/login`)
  session_id = response['session']
  Thread.current[:backend_session] = session_id
end


def stop_backend
  TestUtils::kill($backend_pid)
end


if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('migrations:test')
end

require_relative "../lib/bootstrap"
require_relative "../../backend/app/lib/request_context"

JSONModel::init( { :strict_mode => true, :enum_source => MockEnumSource, :client_mode => true, :url => $backend_url} )


require 'factory_girl'
require_relative 'factories'
include FactoryGirl::Syntax::Methods


def make_test_vocab
  vocab = create(:json_vocab)

  vocab.uri
end
