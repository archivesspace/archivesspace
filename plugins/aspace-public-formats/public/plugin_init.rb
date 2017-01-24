require "net/http"
require "uri"

ArchivesSpacePublic::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

