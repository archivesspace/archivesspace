require "rspec"
require 'jsonmodel'
require 'factory_girl'

include FactoryGirl::Syntax::Methods


$backend = ENV['ASPACE_BACKEND_URL']

unless $backend
  require 'test_utils'

  backend_port = TestUtils::free_port_from(3636)
  $backend = "http://localhost:#{backend_port}"
  $server_pids = []


  $server_pids << TestUtils::start_backend(backend_port,
                           {
                             :realtime_index_backlog_ms => 600000,
                             :session_expire_after_seconds => 300
                           })

  def cleanup
    puts "Shutting down backend"
    $server_pids.each do |pid|
      TestUtils::kill(pid)
    end
  end
end

AppConfig[:backend_url] = $backend

JSONModel::init(:client_mode => true, :strict_mode => true,
                :url => $backend,
                :priority => :high)

auth = JSONModel::HTTP.post_form(
                                 '/users/admin/login', 
                                 {:password => 'admin'}
                                 )

JSONModel::HTTP.current_backend_session = JSON.parse(auth.body)['session']

require_relative '../../backend/spec/factories'

def capture_stderr
  old_stderr, $stderr = $stderr, StringIO.new
  yield
  
  $stderr.string
ensure 
  $stderr = old_stderr
end
