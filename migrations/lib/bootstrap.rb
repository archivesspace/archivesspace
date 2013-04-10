# written for Ruby 1.9.3

# require_relative "../config/config"
require 'config/config-distribution'
require 'jsonmodel'

$dry_mode ||= false

puts AppConfig[:backend_url]

unless $test_mode
  JSONModel::init( { :client_mode => true, :url => AppConfig[:backend_url], :strict_mode => true } )
end

require_relative "crosswalk"
require_relative "importer"
require_relative "parse_queue"

ASpaceImport::init

require_relative "exporter"

ASpaceExport::init

unless $dry_mode || $test_mode
  response = JSON.parse(`curl -F'password=admin' #{AppConfig[:backend_url]}/users/admin/login`)
  session_id = response['session']
  Thread.current[:backend_session] = session_id
end







