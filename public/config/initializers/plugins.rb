module Plugins

  def self.extend_aspace_routes(routes_file)
    ArchivesSpacePublic::Application.config.paths['config/routes.rb'].concat([routes_file])
  end

  def self.add_menu_item(path, label, position = nil)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_menu_item(path, label, position)
    end
  end

  def self.add_record_page_action_proc(record_type, label, icon_css, build_url_proc, position = nil)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_record_page_action_proc(record_type, label, icon_css, build_url_proc, position)
    end
  end

  def self.add_record_page_action_js(record_type, label, icon_css, onclick_javascript, position = nil)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_record_page_action_js(record_type, label, icon_css, onclick_javascript, position)
    end
  end

  def self.add_record_page_action_erb(record_types, erb_partial, position = nil)
    ArchivesSpacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_record_page_action_erb(record_types, erb_partial, position)
    end
  end
end
