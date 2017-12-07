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

  # Setup the Page Action menu items
  $RECORD_PAGE_ACTIONS = {}

  # Add a link page action for a particular jsonmodel record type
  # - record_types: the types to display for e.g, resource, archival_object etc
  # - label: I18n path or string for the label
  # - icon: CSS classes for the Font Awesome icon e.g. 'fa-book'
  # - url_proc: a proc passed the record upon render which must return a string
  #   (the record is passed as a param to the proc)
  # - position: index to include the menu item
  def self.add_record_page_action_proc(record_types, label, icon, url_proc, position = nil)
    action = {
      'label' => label,
      'icon' => icon,
      'url_proc' => url_proc
    }

    ASUtils.wrap(record_types).each do |record_type|
      $RECORD_PAGE_ACTIONS[record_type] ||= []
      if (position.nil?)
        $RECORD_PAGE_ACTIONS[record_type] << action
      else
        $RECORD_PAGE_ACTIONS[record_type].insert(position, action)
      end
    end
  end

  # Add a JavaScript page action for a particular jsonmodel record type
  # - record_types: the types to display for e.g, resource, archival_object etc
  # - label: I18n path or string for the label
  # - icon: CSS classes for the Font Awesome icon e.g. 'fa fa-book fa-3x'
  # - onclick_javascript: a javascript expression to run when the action is clicked
  #   (the record uri and title are available as data attributes on the button element)
  # - position: index to include the menu item
  def self.add_record_page_action_js(record_types, label, icon, onclick_javascript, position = nil)
    action = {
      'label' => label,
      'icon' => icon,
      'onclick_javascript' => onclick_javascript
    }

    ASUtils.wrap(record_types).each do |record_type|
      $RECORD_PAGE_ACTIONS[record_type] ||= []
      if (position.nil?)
        $RECORD_PAGE_ACTIONS[record_type] << action
      else
        $RECORD_PAGE_ACTIONS[record_type].insert(position, action)
      end
    end
  end

# Add an action from an ERB for a particular jsonmodel record type
# - record_types: the types to display for e.g, resource, archival_object etc
# - erb_partial: the path the erb partial
# - position: index to include the menu item
  def self.add_record_page_action_erb(record_types, erb_partial, position = nil)
    action = {
      'erb_partial' => erb_partial,
    }

    ASUtils.wrap(record_types).each do |record_type|
      $RECORD_PAGE_ACTIONS[record_type] ||= []
      if (position.nil?)
        $RECORD_PAGE_ACTIONS[record_type] << action
      else
        $RECORD_PAGE_ACTIONS[record_type].insert(position, action)
      end
    end
  end

  ## Load any default actions:
  # Cite
  if AppConfig[:pui_page_actions_cite]
    add_record_page_action_erb(['resource', 'archival_object', 'digital_object', 'digital_object_component'],
                               'shared/cite_page_action')
  end

  ## Bookmark
  # TODO disabled for now; to be implemented with the bookbag feature
  # if AppConfig[:pui_page_actions_bookmark]
  #   add_record_page_action_js(['resource', 'archival_object', 'digital_object', 'digital_object_component'],
  #                             'actions.bookmark',
  #                             'fa-bookmark',
  #                             'bookmark_page()')
  # end

  # Request
  if AppConfig[:pui_page_actions_request]
    add_record_page_action_erb(['resource', 'archival_object', 'digital_object', 'digital_object_component', 'accession'],
                                'shared/request_page_action')
  end

  ## Print
  if AppConfig[:pui_page_actions_print]
    add_record_page_action_erb(['resource'],
                              'shared/print_page_action')
  end

  # Link to the Staff Interface
  if AppConfig[:pui_enable_staff_link]
    add_record_page_action_erb(['resource', 'archival_object', 'digital_object',
                                'digital_object_component', 'accession', 'subject',
                                'agent_person', 'agent_family', 'agent_corporate_entity',
                                'classification', 'classification_term', 'top_container'],
                               'shared/staff_link_action')
  end

  # Load any custom actions defined in AppConfig:
  ASUtils.wrap(AppConfig[:pui_page_custom_actions]).each do |action|
    ASUtils.wrap(action.fetch('record_type')).each do |record_type|
      $RECORD_PAGE_ACTIONS[record_type] ||= []
      $RECORD_PAGE_ACTIONS[record_type] << action
    end
  end

end

# config public robots.txt
if Rails.root.basename.to_s == 'WEB-INF'  # only need to do this when running out of unpacked .war
  robtxt = ((Pathname.new AppConfig.find_user_config).dirname + 'robots.txt' )
  dest = Rails.root.dirname
  if robtxt.exist? && robtxt.file?  && dest.directory? && dest.writable?
    p "*********    #{robtxt} exists: copying to #{dest} ****** "
    FileUtils.cp( robtxt, dest, :verbose => true  )
  end
end
