# written for Ruby 1.9.3

require_relative "../config/config"
require_relative "../../common/jsonmodel"

unless $test_mode
  JSONModel::init( { :client_mode => true, :url => ASpaceImportConfig::ASPACE_BASE, :strict_mode => true } )
  JSONModel::init( { :client_mode => true, :strict_mode => true } )
end

require_relative "crosswalk"
require_relative "importer"
require_relative "parse_queue"

ASpaceImport::init

require_relative "exporter"

ASpaceExport::init

unless $test_mode
  res = JSON.parse(`curl -F'password=admin' #{ASpaceImportConfig::ASPACE_BASE}/users/admin/login`)
  session_id = res['session']
  puts "Session ID #{session_id}"
  Thread.current[:backend_session] = session_id
end







