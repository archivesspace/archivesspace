require 'test_utils'
require 'config/config-distribution'

$test_mode = true

$backend_port = TestUtils::free_port_from(3636)
$backend_url = "http://localhost:#{$backend_port}"
$expire = 300

$backend_start_fn = proc {
  TestUtils::start_backend($backend_port,
                           {
                             :session_expire_after_seconds => $expire
                           })
}

AppConfig[:backend_url] = $backend


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


class MockEnumSource

  def self.valid?(enum_name, value)
    values_for(enum_name).include?(value)
  end

  def self.values_for(enum_name)
    %w{alpha beta epsilon}
  end

end


JSONModel::init( { :strict_mode => true, :enum_source => MockEnumSource, :client_mode => true, :url => $backend_url} )


require 'factory_girl'
require_relative 'factories'
include FactoryGirl::Syntax::Methods


def make_test_vocab
  vocab = JSONModel(:vocabulary).from_hash("ref_id" => 'test_vocab',
                                          "name" => "Test Vocabulary")
  vocab.save
  
  vocab.uri
end
