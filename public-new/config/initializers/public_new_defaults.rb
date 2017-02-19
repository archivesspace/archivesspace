#require "memoryleak"
# require 'pp'
module PublicNewDefaults
#  pp "initializing resources"
# FIXME do we need to do this in the intializer?
#  Repository.set_repos(ArchivesSpaceClient.new.list_repositories)

# determining the main menu
  $MAIN_MENU = []
  AppConfig[:pui_hide].keys.each do |k|
    unless AppConfig[:pui_hide][k]
      case k
        when :repositories
          $MAIN_MENU.push(['/repositories', 'repository._plural'])
        when :resources
          $MAIN_MENU.push(['/repositories/resources', 'resource._plural'])
        when :digital_objects
          $MAIN_MENU.push(['/objects?limit=digital_object', 'digital_object._plural' ])
        when :accessions
          $MAIN_MENU.push(['/accessions', 'unprocessed'])
        when :subjects
          $MAIN_MENU.push(['/subjects', 'subject._plural'])
        when :agents
          $MAIN_MENU.push(['/agents', 'pui_agent._plural'])
        when :classifications
          $MAIN_MENU.push(['/classifications', 'classification._plural'])
      end
    end
  end

  def self.add_menu_item(path, label, position = nil)
    if position.nil?
      $MAIN_MENU.push([path, label])
    else
      $MAIN_MENU.insert(position, [path, label])
    end
  end
#  Pry::ColorPrinter.pp $MAIN_MENU
#  MemoryLeak::Resources.define(:repository, proc { ArchivesSpaceClient.new.list_repositories }, 60)
#pp MemoryLeak::Resources.get(:repository)

  # determining the record page actions menu
  $RECORD_PAGE_ACTIONS = {}

  # Add a page action for a particular jsonmodel record type
  # - record_type: the type e.g, resource, archival_object etc
  # - label: I18n path or string for the label
  # - icon_css: CSS classes for the Font Awesome icon e.g. 'fa-book'
  # - build_url_proc: a proc passed the record upon render which must return a string
  #   (the record is passed as a param to the proc)  def self.add_record_page_action_javascript(record_type, label, icon_css, build_url_proc = nil, onclick_javascript = nil)
  def self.add_record_page_action_proc(record_type, label, icon_css, build_url_proc)
    $RECORD_PAGE_ACTIONS[record_type] ||= []
    $RECORD_PAGE_ACTIONS[record_type] << {
      'label' => label,
      'icon_css' => icon_css,
      'build_url_proc' => build_url_proc
    }
  end

  # Add a page action for a particular jsonmodel record type
  # - record_type: the type e.g, resource, archival_object etc
  # - label: I18n path or string for the label
  # - icon_css: CSS classes for the Font Awesome icon e.g. 'fa fa-book fa-3x'
  # - onclick_javascript: a javascript expression to run when the action is clicked
  #   (the record uri and title are available as data attributes on the button element)
  def self.add_record_page_action_js(record_type, label, icon_css, onclick_javascript)
    $RECORD_PAGE_ACTIONS[record_type] ||= []
    $RECORD_PAGE_ACTIONS[record_type] << {
      'label' => label,
      'icon_css' => icon_css,
      'onclick_javascript' => onclick_javascript
    }
  end


end
