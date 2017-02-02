module Plugins

  def self.extend_aspace_routes(routes_file)
    ArchivesspacePublic::Application.config.paths['config/routes.rb'].concat([routes_file])
  end

  def self.add_menu_item(path, label, position = nil)
    ArchivesspacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_menu_item(path, label, position)
    end
  end
end
