module Plugins

  def self.extend_aspace_routes(routes_file)
    ArchivesSpacePublic::Application.config.paths['config/routes.rb'].concat([routes_file])
  end

  def self.add_menu_item(path, label, position = nil)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_menu_item(path, label, position)
    end
  end
end
