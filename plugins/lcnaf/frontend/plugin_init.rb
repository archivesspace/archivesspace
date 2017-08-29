if ArchivesSpace::Application.respond_to?(:extend_aspace_routes)
  # > v2.0 way of defining routes
  ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))
else
  # < v2.0 way of defining routes
  my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
  ArchivesSpace::Application.config.paths['config/routes'].concat(my_routes)
end
