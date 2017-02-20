Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))
Plugins::add_menu_item('/plugin/pugs', 'plugin.pugs.menu_label')
Plugins::add_record_page_action_proc('resource', 'plugin.pugs.resource_action', 'fa-paw', proc {|record|
  'http://example.com/pugs?uri='+record.uri
}, 0)
Plugins::add_record_page_action_js('archival_object', 'plugin.pugs.archival_object_action', 'fa-paw', "alert('PUGS ARE GREAT! URI:'+$(this).data('uri'));", 0)