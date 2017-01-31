require "net/http"
require "uri"

my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
ArchivesSpacePublic::Application.config.paths['config/routes'].concat(my_routes)

