require "net/http"
require "uri"

my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
ArchivesSpacePublic::Application.config.paths['config/routes'].concat(my_routes)

AppConfig[:public_formats_resource_links] = []
AppConfig[:public_formats_digital_object_links] = []
AppConfig[:xsltproc_path] = nil
AppConfig[:xslt_path] = nil
