module Plugins

  def self.extend_aspace_routes(routes_file)
    ArchivesSpacePublic::Application.config.paths['config/routes.rb'].concat([routes_file])
  end

  def self.add_menu_item(path, label, position = nil)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_menu_item(path, label, position)
    end
  end

  def self.add_record_page_action_proc(record_type, label, icon_css, build_url_proc)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_record_page_action_proc(record_type, label, icon_css, build_url_proc)
    end
  end

  def self.add_record_page_action_js(record_type, label, icon_css, onclick_javascript)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_record_page_action_js(record_type, label, icon_css, onclick_javascript)
    end
  end
end
