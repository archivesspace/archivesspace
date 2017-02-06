if ENV['ASPACE_PUBLIC_NEW'] == 'true'
  raise 'The aspace-public-formats plugin is only compatible with the original public user interface'
end

require "net/http"
require "uri"

ArchivesSpacePublic::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

