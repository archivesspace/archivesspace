ArchivesSpace::Application.routes.draw do

  scope AppConfig[:frontend_prefix] do
    match 'jobs/:id/cancel' => 'jobs#cancel', :via => [:post]
    match 'jobs/:id/log' => 'jobs#log', :via => [:get]
    match 'jobs/:id/status' => 'jobs#status', :via => [:get]
    match 'jobs/:id/records' => 'jobs#records', :via => [:get]
    resources :jobs

    match 'login' => "session#login", :via => :post
    match 'login' => "session#login_inline", :via => :get
    match 'logout' => "session#logout", :via => :get
    match 'select_user' => "session#select_user", :via => :get
    match 'become_user' => "session#become_user", :via => :post
    match 'check_session' => "session#check_session", :via => :get
    match 'has_session' => "session#has_session", :via => :get

    match 'repositories/select' => 'repositories#select', :via => [:post]
    match 'repositories/:id/transfer' => 'repositories#transfer', :via => [:get]
    match 'repositories/:id/transfer' => 'repositories#run_transfer', :via => [:post]
    resources :repositories
    match 'repositories/:id' => 'repositories#update', :via => [:post]
    match 'repositories/:id/delete' => 'repositories#delete', :via => [:post]
    match 'repositories/delete_records' => 'repositories#delete_records', :via => [:post]

    match 'users/manage_access' => 'users#manage_access', :via => [:get]
    match 'users/:id/edit_groups' => 'users#edit_groups', :via => [:get]
    match 'users/:id/edit' => 'users#edit', :via => [:get]
    match 'users/:id/update_groups' => 'users#update_groups', :via => [:post]
    match 'users/new' => 'users#new', :via => [:get]
    match 'users/complete' => 'users#complete', :via => [:get]
    match 'users/:id' => 'users#show', :via => [:get]
    match 'users/:id' => 'users#update', :via => [:post]
    match 'users/:id/delete' => 'users#delete', :via => [:post]
    resources :users

    resources :groups
    match 'groups/:id' => 'groups#update', :via => [:post]
    match 'groups/:id/delete' => 'groups#delete', :via => [:post]

    resources :accessions
    match 'accessions/:id' => 'accessions#update', :via => [:post]
    match 'accessions/:id/suppress' => 'accessions#suppress', :via => [:post]
    match 'accessions/:id/unsuppress' => 'accessions#unsuppress', :via => [:post]
    match 'accessions/:id/delete' => 'accessions#delete', :via => [:post]
    match 'accessions/:id/transfer' => 'accessions#transfer', :via => [:post]

    match 'archival_objects/:id/transfer' => 'archival_objects#transfer', :via => [:post]
    match 'archival_objects/validate_rows' => 'archival_objects#validate_rows', :via => [:post]
    resources :archival_objects
    match 'archival_objects/:id' => 'archival_objects#update', :via => [:post]
    match 'archival_objects/:id/delete' => 'archival_objects#delete', :via => [:post]
    match 'archival_objects/:id/rde' => 'archival_objects#rde', :via => [:get]
    match 'archival_objects/:id/add_children' => 'archival_objects#add_children', :via => [:post]
    match 'archival_objects/:id/accept_children' => 'archival_objects#accept_children', :via => [:post]
    match 'archival_objects/:id/suppress' => 'archival_objects#suppress', :via => [:post]
    match 'archival_objects/:id/unsuppress' => 'archival_objects#unsuppress', :via => [:post]

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

    match 'digital_object_components/validate_rows' => 'digital_object_components#validate_rows', :via => [:post]
    resources :digital_object_components
    match 'digital_object_components/:id' => 'digital_object_components#update', :via => [:post]
    match 'digital_object_components/:id/delete' => 'digital_object_components#delete', :via => [:post]
    match 'digital_object_components/:id/accept_children' => 'digital_object_components#accept_children', :via => [:post]
    match 'digital_object_components/:id/rde' => 'digital_object_components#rde', :via => [:get]
    match 'digital_object_components/:id/add_children' => 'digital_object_components#add_children', :via => [:post]
    match 'digital_object_components/:id/suppress' => 'digital_object_components#suppress', :via => [:post]
    match 'digital_object_components/:id/unsuppress' => 'digital_object_components#unsuppress', :via => [:post]

    resources :resources
    match 'resources/:id/container_labels' => 'exports#container_labels', :via => [:get]
    match 'resources/:id/download_marc' => 'exports#download_marc', :via => [:get]
    match 'resources/:id/download_ead' => 'exports#download_ead', :via => [:get]
    match 'resources/:id' => 'resources#update', :via => [:post]
    match 'resources/:id/delete' => 'resources#delete', :via => [:post]
    match 'resources/:id/rde' => 'resources#rde', :via => [:get]
    match 'resources/:id/add_children' => 'resources#add_children', :via => [:post]
    match 'resources/:id/publish' => 'resources#publish', :via => [:post]
    match 'resources/:id/accept_children' => 'resources#accept_children', :via => [:post]
    match 'resources/:id/merge' => 'resources#merge', :via => [:post]
    match 'resources/:id/transfer' => 'resources#transfer', :via => [:post]
    match 'resources/:id/tree' => 'resources#tree', :via => [:get]
    match 'resources/:id/suppress' => 'resources#suppress', :via => [:post]
    match 'resources/:id/unsuppress' => 'resources#unsuppress', :via => [:post]

    resources :classifications
    match 'classifications/:id' => 'classifications#update', :via => [:post]
    match 'classifications/:id/delete' => 'classifications#delete', :via => [:post]
    match 'classifications/:id/accept_children' => 'classifications#accept_children', :via => [:post]
    match 'classifications/:id/tree' => 'classifications#tree', :via => [:get]

    resources :classification_terms
    match 'classification_terms/:id' => 'classification_terms#update', :via => [:post]
    match 'classification_terms/:id/delete' => 'classification_terms#delete', :via => [:post]
    match 'classification_terms/:id/accept_children' => 'classification_terms#accept_children', :via => [:post]

    resources :subjects
    match 'subjects/:id' => 'subjects#update', :via => [:post]
    match 'subjects/terms/complete' => 'subjects#terms_complete', :via => [:get]
    match 'subjects/:id/delete' => 'subjects#delete', :via => [:post]
    match 'subjects/:id/merge' => 'subjects#merge', :via => [:post]

    match 'locations/batch' => 'locations#batch', :via => [:get]
    match 'locations/batch_create' => 'locations#batch_create', :via => [:post]
    match 'locations/batch_preview' => 'locations#batch_preview', :via => [:post]
    resources :locations
    match 'locations/:id' => 'locations#update', :via => [:post]
    match 'locations/:id/delete' => 'locations#delete', :via => [:post]

    resources :events
    match 'events/:id' => 'events#update', :via => [:post]
    match 'events/:id/delete' => 'events#delete', :via => [:post]

    match 'agents/contact_form' => 'agents#contact_form', :via => [:get]
    match 'agents/:agent_type/name_form' => 'agents#name_form', :via => [:get]
    match 'agents/:agent_type/create' => 'agents#create', :via => [:post]
    match 'agents/:agent_type/new' => 'agents#new', :via => [:get]
    match 'agents/:agent_type/:id/edit' => 'agents#edit', :via => [:get]
    match 'agents/:agent_type/:id/update' => 'agents#update', :via => [:post]
    match 'agents/:agent_type/:id/download_eac' => 'exports#download_eac', :via => [:get]
    match 'agents/:agent_type/:id' => 'agents#show', :via => [:get]
    match 'agents' => 'agents#index', :via => [:get]
    match 'agents/:agent_type/:id/delete' => 'agents#delete', :via => [:post]
    match 'agents/:id/merge' => 'agents#merge', :via => [:post]


    resources :collection_management

    match 'test/shutdown' => 'tests#shutdown', :via => [:get]

    match 'search' => 'search#do_search', :via => [:get]
    match 'advanced_search' => 'search#advanced_search', :via => [:get]

    match 'resolve/edit' => 'resolver#resolve_edit', :via => [:get]
    match 'resolve/readonly' => 'resolver#resolve_readonly', :via => [:get]

    match 'enumerations/list' => 'enumerations#list', :via => [:get]
    match 'enumerations/delete' => 'enumerations#delete', :via => [:get]
    match 'enumerations/set_default/:id' => 'enumerations#set_default', :via => [:post] 
    match 'enumerations/destroy/:id' => 'enumerations#destroy', :via => [:post]
    match 'enumerations/merge/:id' => 'enumerations#merge', :via => [:post]
    resources :enumerations

    match 'reports' => 'reports#index', :via => [:get]
    match 'reports/download' => 'reports#download', :via => [:post]

    match 'update_monitor/poll' => 'update_monitor#poll', :via => [:post]

    match 'batch_delete/archival_records' => 'batch_delete#archival_records', :via => [:post]
    match 'batch_delete/subjects' => 'batch_delete#subjects', :via => [:post]
    match 'batch_delete/agents' => 'batch_delete#agents', :via => [:post]
    match 'batch_delete/classifications' => 'batch_delete#classifications', :via => [:post]

    match 'generate_sequence' => 'utils#generate_sequence', :via => [:get]

    resources :preferences
    match 'preferences/:id' => 'preferences#update', :via => [:post]

    if Plugins.system_menu_items?
      scope '/plugins' do
        Plugins.system_menu_items.each do |plugin|
          unless Plugins.config_for(plugin)['no_automatic_routes']
            resources plugin.intern
          end
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

    root :to => 'welcome#index'

  end

end
