ArchivesSpace::Application.routes.draw do

  scope AppConfig[:frontend_proxy_prefix] do
    match 'jobs/:id/cancel' => 'jobs#cancel', :via => [:post]
    match 'jobs/:id/log' => 'jobs#log', :via => [:get]
    match 'jobs/:id/status' => 'jobs#status', :via => [:get]
    match 'jobs/:id/records' => 'jobs#records', :via => [:get]
    match 'jobs/:job_id/file/:id' => 'jobs#download_file', :via => [:get]
    resources :jobs

    match 'login' => "session#login", :via => :post
    match 'login' => "session#login_inline", :via => :get
    match 'logout' => "session#logout", :via => :get
    match 'select_user' => "session#select_user", :via => :get
    match 'become_user' => "session#become_user", :via => :post
    match 'check_session' => "session#check_session", :via => :get
    match 'has_session' => "session#has_session", :via => :get

    match 'repositories/reorder' => 'repositories#reorder', :via => [:get]
    match 'repositories/reorder' => 'repositories#run_reorder', :via => [:post]
    match 'repositories/select' => 'repositories#select', :via => [:post]
    match 'repositories/:id/transfer' => 'repositories#transfer', :via => [:get]
    match 'repositories/:id/transfer' => 'repositories#run_transfer', :via => [:post]
    resources :repositories
    match 'repositories/:id' => 'repositories#update', :via => [:post]
    match 'repositories/:id/delete' => 'repositories#delete', :via => [:post]
    match 'repositories/delete_records' => 'repositories#delete_records', :via => [:post]
    match('repositories/search/typeahead' => 'repositories#typeahead', :via => [:get])

    match 'users/manage_access' => 'users#manage_access', :via => [:get]
    match 'users/edit_self' => 'users#edit_self', :via => [:get]
    match 'users/update_self' => 'users#update_self', :via => [:post]
    match 'users/edit_password' => 'users#password_form', :via => [:get]
    match 'users/recover_password' => 'users#recover_password', :via => [:post]
    match 'users/update_password' => 'users#update_password', :via => [:post]
    match 'users/:id/edit_groups' => 'users#edit_groups', :via => [:get]
    match 'users/:id/edit' => 'users#edit', :via => [:get]
    match 'users/:id/update_groups' => 'users#update_groups', :via => [:post]
    match 'users/new' => 'users#new', :via => [:get]
    match 'users/complete' => 'users#complete', :via => [:get]
    match 'users/:id' => 'users#show', :via => [:get]
    match 'users/:id' => 'users#update', :via => [:post]
    match 'users/:id/delete' => 'users#delete', :via => [:post]
    match('/users/:id/activate' => 'users#activate', :via => [:get], :as => :user_activate)
    match('/users/:id/deactivate' => 'users#deactivate', :via => [:get], :as => :user_deactivate)
    match 'users/:username/:token' => 'session#token_login', :via => [:get], constraints: { username: /[^\/]+/ }

    resources :users

    resources :groups
    match 'groups/:id' => 'groups#update', :via => [:post]
    match 'groups/:id/delete' => 'groups#delete', :via => [:post]

    match 'accessions/defaults' => 'accessions#defaults', :via => [:get]
    match 'accessions/defaults' => 'accessions#update_defaults', :via => [:post]
    resources :accessions
    match 'accessions/:id' => 'accessions#update', :via => [:post]
    match 'accessions/:id/suppress' => 'accessions#suppress', :via => [:post]
    match 'accessions/:id/unsuppress' => 'accessions#unsuppress', :via => [:post]
    match 'accessions/:id/delete' => 'accessions#delete', :via => [:post]
    match 'accessions/:id/transfer' => 'accessions#transfer', :via => [:post]

    match 'archival_objects/:id/transfer' => 'archival_objects#transfer', :via => [:post]
    match 'archival_objects/validate_rows' => 'archival_objects#validate_rows', :via => [:post]
    match 'archival_objects/defaults' => 'archival_objects#defaults', :via => [:get]
    match 'archival_objects/defaults' => 'archival_objects#update_defaults', :via => [:post]
    resources :archival_objects
    match 'archival_objects/:id' => 'archival_objects#update', :via => [:post]
    match 'archival_objects/:id/delete' => 'archival_objects#delete', :via => [:post]
    match 'archival_objects/:id/rde' => 'archival_objects#rde', :via => [:get]
    match 'archival_objects/:id/add_children' => 'archival_objects#add_children', :via => [:post]
    match 'archival_objects/:id/publish' => 'archival_objects#publish', :via => [:post]
    match 'archival_objects/:id/unpublish' => 'archival_objects#unpublish', :via => [:post]
    match 'archival_objects/:id/accept_children' => 'archival_objects#accept_children', :via => [:post]
    match 'archival_objects/:id/suppress' => 'archival_objects#suppress', :via => [:post]
    match 'archival_objects/:id/unsuppress' => 'archival_objects#unsuppress', :via => [:post]
    match 'archival_objects/:id/models_in_graph' => 'archival_objects#models_in_graph', :via => [:get]

    match 'digital_objects/defaults' => 'digital_objects#defaults', :via => [:get]
    match 'digital_objects/defaults' => 'digital_objects#update_defaults', :via => [:post]
    resources :digital_objects
    match 'digital_objects/:id/download_dc' => 'exports#download_dc', :via => [:get]
    match 'digital_objects/:id/download_mets' => 'exports#download_mets', :via => [:get]
    match 'digital_objects/:id/download_mods' => 'exports#download_mods', :via => [:get]
    match 'digital_objects/:id' => 'digital_objects#update', :via => [:post]
    match 'digital_objects/:id/delete' => 'digital_objects#delete', :via => [:post]
    match 'digital_objects/:id/publish' => 'digital_objects#publish', :via => [:post]
    match 'digital_objects/:id/accept_children' => 'digital_objects#accept_children', :via => [:post]
    match 'digital_objects/:id/merge' => 'digital_objects#merge', :via => [:post]
    match 'digital_objects/:id/transfer' => 'digital_objects#transfer', :via => [:post]
    match 'digital_objects/:id/tree' => 'digital_objects#tree', :via => [:get]
    match 'digital_objects/:id/rde' => 'digital_objects#rde', :via => [:get]
    match 'digital_objects/:id/add_children' => 'digital_objects#add_children', :via => [:post]
    match 'digital_objects/:id/suppress' => 'digital_objects#suppress', :via => [:post]
    match 'digital_objects/:id/unsuppress' => 'digital_objects#unsuppress', :via => [:post]

    match 'digital_objects/:id/tree/root' => 'digital_objects#tree_root', :via => [:get]
    match 'digital_objects/:id/tree/node' => 'digital_objects#tree_node', :via => [:get]
    match 'digital_objects/:id/tree/node_from_root' => 'digital_objects#node_from_root', :via => [:get]
    match 'digital_objects/:id/tree/waypoint' => 'digital_objects#tree_waypoint', :via => [:get]

    match 'digital_object_components/validate_rows' => 'digital_object_components#validate_rows', :via => [:post]
    match 'digital_object_components/defaults' => 'digital_object_components#defaults', :via => [:get]
    match 'digital_object_components/defaults' => 'digital_object_components#update_defaults', :via => [:post]
    resources :digital_object_components
    match 'digital_object_components/:id' => 'digital_object_components#update', :via => [:post]
    match 'digital_object_components/:id/delete' => 'digital_object_components#delete', :via => [:post]
    match 'digital_object_components/:id/accept_children' => 'digital_object_components#accept_children', :via => [:post]
    match 'digital_object_components/:id/rde' => 'digital_object_components#rde', :via => [:get]
    match 'digital_object_components/:id/add_children' => 'digital_object_components#add_children', :via => [:post]
    match 'digital_object_components/:id/suppress' => 'digital_object_components#suppress', :via => [:post]
    match 'digital_object_components/:id/unsuppress' => 'digital_object_components#unsuppress', :via => [:post]

    match 'resources/defaults' => 'resources#defaults', :via => [:get]
    match 'resources/defaults' => 'resources#update_defaults', :via => [:post]
    resources :resources
    match 'resources/:id/container_labels' => 'exports#container_labels', :via => [:get]
    match 'resources/:id/container_tempate' => 'exports#container_template', :via => [:get]
    match 'resources/:id/digital_object_template' => 'exports#digital_object_template', :via => [:get]
    match 'resources/:id/download_marc' => 'exports#download_marc', :via => [:get]
    match 'resources/:id/download_ead' => 'exports#download_ead', :via => [:get]
    match 'resources/:id/print_to_pdf' => 'exports#print_to_pdf', :via => [:get]
    match 'resources/:id/resource_duplicate' => 'exports#resource_duplicate', :via => [:post]
    match 'resources/:id' => 'resources#update', :via => [:post]
    match 'resources/:id/delete' => 'resources#delete', :via => [:post]
    match 'resources/:id/rde' => 'resources#rde', :via => [:get]
    match 'resources/:id/add_children' => 'resources#add_children', :via => [:post]
    match 'resources/:id/publish' => 'resources#publish', :via => [:post]
    match 'resources/:id/unpublish' => 'resources#unpublish', :via => [:post]
    match 'resources/:id/accept_children' => 'resources#accept_children', :via => [:post]
    match 'resources/:id/merge' => 'resources#merge', :via => [:post]
    match 'resources/:id/transfer' => 'resources#transfer', :via => [:post]
    match 'resources/:rid/getbulkfile' => 'bulk_import#get_file', :via => [:post]
    match 'resources/:rid/getbulkfile' => 'bulk_import#get_file', :via => [:get]
    match 'resources/:id/link_top_containers' => 'bulk_import#link_top_containers_to_archival_objects', :via => [:post]

    match 'resources/:id/tree/root' => 'resources#tree_root', :via => [:get]
    match 'resources/:id/tree/node' => 'resources#tree_node', :via => [:get]
    match 'resources/:id/tree/node_from_root' => 'resources#node_from_root', :via => [:get]
    match 'resources/:id/tree/waypoint' => 'resources#tree_waypoint', :via => [:get]

    match 'resources/:id/suppress' => 'resources#suppress', :via => [:post]
    match 'resources/:id/unsuppress' => 'resources#unsuppress', :via => [:post]
    match 'resources/:id/models_in_graph' => 'resources#models_in_graph', :via => [:get]

    match 'classifications/defaults' => 'classifications#defaults', :via => [:get]
    match 'classifications/defaults' => 'classifications#update_defaults', :via => [:post]
    resources :classifications
    match 'classifications/:id' => 'classifications#update', :via => [:post]
    match 'classifications/:id/delete' => 'classifications#delete', :via => [:post]
    match 'classifications/:id/accept_children' => 'classifications#accept_children', :via => [:post]
    match 'classifications/:id/tree' => 'classifications#tree', :via => [:get]

    match 'classifications/:id/tree/root' => 'classifications#tree_root', :via => [:get]
    match 'classifications/:id/tree/node' => 'classifications#tree_node', :via => [:get]
    match 'classifications/:id/tree/node_from_root' => 'classifications#node_from_root', :via => [:get]
    match 'classifications/:id/tree/waypoint' => 'classifications#tree_waypoint', :via => [:get]

    match 'classification_terms/defaults' => 'classification_terms#defaults', :via => [:get]
    match 'classification_terms/defaults' => 'classification_terms#update_defaults', :via => [:post]
    resources :classification_terms
    match 'classification_terms/:id' => 'classification_terms#update', :via => [:post]
    match 'classification_terms/:id/delete' => 'classification_terms#delete', :via => [:post]
    match 'classification_terms/:id/accept_children' => 'classification_terms#accept_children', :via => [:post]

    match 'subjects/defaults' => 'subjects#defaults', :via => [:get]
    match 'subjects/defaults' => 'subjects#update_defaults', :via => [:post]
    resources :subjects
    match 'subjects/:id' => 'subjects#update', :via => [:post]
    match 'subjects/terms/complete' => 'subjects#terms_complete', :via => [:get]
    match 'subjects/:id/delete' => 'subjects#delete', :via => [:post]
    match 'subjects/:id/merge' => 'subjects#merge', :via => [:post]

    match 'locations/batch' => 'locations#batch', :via => [:get, :post]
    match 'locations/batch_create' => 'locations#batch_create', :via => [:post]
    match 'locations/batch_preview' => 'locations#batch_preview', :via => [:post]
    match 'locations/batch_edit' => 'locations#batch_edit', :via => [:post]

    match 'locations/defaults' => 'locations#defaults', :via => [:get]
    match 'locations/defaults' => 'locations#update_defaults', :via => [:post]
    match 'locations/search' => 'locations#search', :via => [:get]
    resources :locations
    match 'locations/:id' => 'locations#update', :via => [:post]
    match 'locations/:id/delete' => 'locations#delete', :via => [:post]

    match 'events/defaults' => 'events#defaults', :via => [:get]
    match 'events/defaults' => 'events#update_defaults', :via => [:post]
    resources :events
    match 'events/:id' => 'events#update', :via => [:post]
    match 'events/:id/delete' => 'events#delete', :via => [:post]

    match 'agents/contact_form' => 'agents#contact_form', :via => [:get]
    match 'agents/:agent_type/name_form' => 'agents#name_form', :via => [:get]
    match 'agents/:agent_type/create' => 'agents#create', :via => [:post]
    match 'agents/:agent_type/new' => 'agents#new', :via => [:get]
    match 'agents/:agent_type/defaults' => 'agents#defaults', :via => [:get]
    match 'agents/:agent_type/defaults' => 'agents#update_defaults', :via => [:post]
    match 'agents/:agent_type/required' => 'agents#required', :via => [:get]
    match 'agents/:agent_type/required' => 'agents#update_required', :via => [:post]
    match 'agents/:agent_type/:id/edit' => 'agents#edit', :via => [:get]
    match 'agents/:agent_type/:id/update' => 'agents#update', :via => [:post]
    match 'agents/:agent_type/:id/download_eac' => 'exports#download_eac', :via => [:get]
    match 'agents/:agent_type/:id/download_marc_auth' => 'exports#download_marc_auth', :via => [:get]
    match 'agents/:agent_type/:id' => 'agents#show', :via => [:get]
    match 'agents' => 'agents#index', :via => [:get]
    match 'agents/:agent_type/:id/delete' => 'agents#delete', :via => [:post]
    match 'agents/:agent_type/:id/publish' => 'agents#publish', :via => [:post]
    match 'agents/merge' => 'agents#merge', :via => [:post]
    match 'agents/:agent_type/:id/merge_selector' => 'agents#merge_selector', :via => [:post]
    match 'agents/:agent_type/:id/merge_detail' => 'agents#merge_detail', :via => [:post]
    match 'agents/:agent_type/:id/merge_preview' => 'agents#merge_preview', :via => [:post]

    resources :collection_management

    match 'test/shutdown' => 'tests#shutdown', :via => [:get]

    match 'search' => 'search#do_search', :via => [:get]
    match 'advanced_search' => 'search#advanced_search', :via => [:get]

    match 'resolve/edit' => 'resolver#resolve_edit', :via => [:get]
    match 'resolve/readonly' => 'resolver#resolve_readonly', :via => [:get]

    match 'enumerations/list' => 'enumerations#list', :via => [:get]
    match 'enumerations/csv' => 'enumerations#csv', :via => [:get]
    match 'enumerations/delete' => 'enumerations#delete', :via => [:get]
    match 'enumerations/set_default/:id' => 'enumerations#set_default', :via => [:post]
    match 'enumerations/destroy/:id' => 'enumerations#destroy', :via => [:post]
    match 'enumerations/merge/:id' => 'enumerations#merge', :via => [:post]
    resources :enumerations

    match 'enumerations/:id/enumeration_value/:enumeration_value_id' => 'enumerations#update_value', :via => [:post]



    match 'reports' => 'reports#index', :via => [:get]
    match 'reports/download' => 'reports#download', :via => [:post]

    match 'update_monitor/poll' => 'update_monitor#poll', :via => [:post]

    match 'batch_delete/archival_records' => 'batch_delete#archival_records', :via => [:post]
    match 'batch_delete/subjects' => 'batch_delete#subjects', :via => [:post]
    match 'batch_delete/agents' => 'batch_delete#agents', :via => [:post]
    match 'batch_delete/classifications' => 'batch_delete#classifications', :via => [:post]
    match 'batch_delete/locations' => 'batch_delete#locations', :via => [:post]
    match 'batch_delete/assessments' => 'batch_delete#assessments', :via => [:post]
    match 'batch_delete/container_profiles' => 'batch_delete#container_profiles', :via => [:post]

    match 'batch_merge/container_profiles' => 'batch_merge#container_profiles', :via => [:post]

    match 'generate_sequence' => 'utils#generate_sequence', :via => [:get]

    match 'schema/:resource_type/properties' => 'utils#list_properties', :via => [:get]

    match 'shortcuts' => 'utils#shortcuts', :via => [:get]
    match 'notes/note_order' => 'utils#note_order', :via =>[:get]

    resources :preferences
    match 'preferences/:id' => 'preferences#update', :via => [:post]
    match 'preferences/:id/reset' => 'preferences#reset', :via => [:post]

    match('bulk_archival_object_updater/download' => 'bulk_archival_object_updater#download_form', :via => [:get])
    match('bulk_archival_object_updater/download' => 'bulk_archival_object_updater#download', :via => [:post])

    resources :rde_templates
    match 'rde_templates/batch_delete' => 'rde_templates#batch_delete', :via => [:post]

    resources :container_profiles
    match('container_profiles/search/typeahead' => 'container_profiles#typeahead', :via => [:get])
    match('container_profiles/bulk_operations/update_barcodes' => 'top_containers#update_barcodes', :via => [:post])
    match('container_profiles/bulk_operations/update_indicators' => 'top_containers#update_indicators', :via => [:post])
    match('container_profiles/bulk_operations/update_locations' => 'top_containers#update_locations', :via => [:post])

    match('container_profiles/:id' => 'container_profiles#update', :via => [:post])
    match('container_profiles/:id/delete' => 'container_profiles#delete', :via => [:post])

    resources :top_containers
    match('top_containers/search/typeahead' => 'top_containers#typeahead', :via => [:get])
    match('top_containers/bulk_operations/search' => 'top_containers#bulk_operations', :via => [:get])
    match('top_containers/bulk_operations/search' => 'top_containers#bulk_operation_search', :via => [:post])
    match('top_containers/bulk_operations/browse' => 'top_containers#bulk_operations_browse', :via => [:get, :post])
    match('top_containers/bulk_operations/update' => 'top_containers#bulk_operation_update', :via => [:post])
    match('top_containers/batch_delete' => 'top_containers#batch_delete', :via => [:post])
    match('top_containers/merge' => 'top_containers#batch_merge', :via => [:post])
    match('top_containers/:id' => 'top_containers#update', :via => [:post])
    match('top_containers/:id/delete' => 'top_containers#delete', :via => [:post])

    match('extent_calculator' => 'extent_calculator#report', :via => [:get])
    match('date_calculator/calculate' => 'date_calculator#calculate', :via => [:post])
    match('date_calculator/create_date' => 'date_calculator#create_date', :via => [:post])

    resources :location_profiles
    match('location_profiles/search/typeahead' => 'location_profiles#typeahead', :via => [:get])
    match('location_profiles/:id' => 'location_profiles#update', :via => [:post])
    match('location_profiles/:id/delete' => 'location_profiles#delete', :via => [:post])

    match('space_calculator' => 'space_calculator#show', :via => [:get])
    match('space_calculator' => 'space_calculator#calculate', :via => [:post])

    match 'assessments/embedded_search' => 'assessments#embedded_search', :via => [:get]
    resources :assessments
    match 'assessments/:id' => 'assessments#update', :via => [:post]
    match 'assessments/:id/delete' => 'assessments#delete', :via => [:post]
    match 'assessment_attributes' => 'assessment_attributes#edit', :via => [:get]
    match 'assessment_attributes' => 'assessment_attributes#update', :via => [:post]

    match 'oai_config/edit'   => 'oai_config#edit',   :via => [:get]
    match 'oai_config/update' => 'oai_config#update', :via => [:post]


    if AppConfig[:enable_custom_reports]
      resources :custom_report_templates
      match('custom_report_templates/:id/delete' => 'custom_report_templates#delete', :via => [:post])
      match('custom_report_templates/:id' => 'custom_report_templates#update', :via => [:post])
      match('custom_report_templates/:id/copy' => 'custom_report_templates#copy', :via => [:get])
      match('custom_report_templates/:id' => 'custom_report_templates#show', :via => [:get])
    end

    match 'ark_update' => 'ark_update#update', :via => [:post]
    match 'bulk_import_templates' => 'bulk_import_templates#index', via: [:get]
    match 'bulk_import_templates/download' => 'bulk_import_templates#download', via: [:get]


    if Plugins.system_menu_items?
      scope '/plugins' do
        Plugins.system_menu_items.each do |plugin|
          unless Plugins.config_for(plugin)['no_automatic_routes']
            resources plugin.intern
          end
        end
      end
      if Plugins.repository_menu_items?
        scope '/plugins' do
          Plugins.repository_menu_items.each do |plugin|
            unless Plugins.config_for(plugin)['no_automatic_routes']
              resources plugin.intern
            end
          end
        end
      end
    end

    match "system_info" => "system_info#show", :via => [ :get ]
    match "system_info/log" => "system_info#stream_log", :via => [:get]

    root :to => 'welcome#index'
  end
end
