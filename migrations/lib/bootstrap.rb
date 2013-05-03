require 'config/config-distribution'
require 'jsonmodel'
require 'logger'

# Bootstrap for import tools running
# in standalone mode.

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

class MockEnumSource
  def self.valid?(enum_name, value)
    [true, false].sample
  end

  def self.values_for(enum_name)
    %w{alpha beta epsilon}
  end
end


$dry_mode ||= false

unless $test_mode
  begin
    json_model_opts = { :client_mode => true, :url => AppConfig[:backend_url], :strict_mode => true }
    JSONModel::init(json_model_opts)
  rescue StandardError => e
      $log.warn("Exception #{e.to_s}")
    if e.to_s =~ /[C|c]onnection refused/ && $dry_mode
      $log.warn("Cannot connect to the backend, it seems. But since this is a dry run, we'll proceed anyway, using mock terms for controlled vocabularies.")
      json_model_opts[:enum_source] = MockEnumSource
      JSONModel::init( json_model_opts )
    else
      $log.warn("Try using the dry-run option if you don't have a backend service running")
      raise e
    end
  end  
end

require_relative "importer"
require_relative "parse_queue"

ASpaceImport::init

unless $dry_mode || $test_mode
  response = JSON.parse(`curl -F'password=admin' #{AppConfig[:backend_url]}/users/admin/login`)
  session_id = response['session']
  Thread.current[:backend_session] = session_id
end







