ArchivesSpace::Application.routes.draw do

  get "import/index"
  post "import/upload"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  match 'login' => "session#login", :via => :post
  match 'logout' => "session#logout", :via => :get

  match 'webhook/notify' => 'webhook#notify', :via => :post

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  resources :repository do
    get 'new'
    post 'create'
  end
  match 'repository/select/:id' => 'repository#select', :via => [:post]

  match 'users/:id/edit' => 'users#edit', :via => [:get]
  match 'users/new' => 'users#new', :via => [:get]
  match 'users/:id' => 'users#show', :via => [:get]
  match 'users/:id' => 'users#update', :via => [:post]
  resources :users

  resources :groups
  match 'groups/:id' => 'groups#update', :via => [:post]

  resources :accessions
  match 'accessions/:id' => 'accessions#update', :via => [:post]
  match 'accessions/:id/suppress' => 'accessions#suppress', :via => [:post]
  match 'accessions/:id/unsuppress' => 'accessions#unsuppress', :via => [:post]
  match 'accessions/:id/delete' => 'accessions#delete', :via => [:post]

  resources :archival_objects
  match 'archival_objects/:id' => 'archival_objects#update', :via => [:post]
  match 'archival_objects/:id/parent' => 'archival_objects#parent', :via => [:post]

  resources :digital_objects
  match 'digital_objects/:id/download_dc' => 'exports#download_dc', :via => [:get]
  match 'digital_objects/:id/download_mets' => 'exports#download_mets', :via => [:get]
  match 'digital_objects/:id/download_mods' => 'exports#download_mods', :via => [:get]
  match 'digital_objects/:id' => 'digital_objects#update', :via => [:post]

  resources :digital_object_components
  match 'digital_object_components/:id' => 'digital_object_components#update', :via => [:post]
  match 'digital_object_components/:id/parent' => 'digital_object_components#parent', :via => [:post]

  resources :resources
  match 'resources/:id/download_marc' => 'exports#download_marc', :via => [:get]
  match 'resources/:id/download_ead' => 'exports#download_ead', :via => [:get]
  match 'resources/:id' => 'resources#update', :via => [:post]

  resources :subjects
  match 'subjects/:id' => 'subjects#update', :via => [:post]

  resources :locations
  match 'locations/:id' => 'locations#update', :via => [:post]

  resources :events
  match 'events/:id' => 'events#update', :via => [:post]

  match 'agents/contact_form' => 'agents#contact_form', :via => [:get]
  match 'agents/:type/name_form' => 'agents#name_form', :via => [:get]
  match 'agents/:type/create' => 'agents#create', :via => [:post]
  match 'agents/:type/new' => 'agents#new', :via => [:get]
  match 'agents/:type/:id/edit' => 'agents#edit', :via => [:get]
  match 'agents/:type/:id/update' => 'agents#update', :via => [:post]
  match 'agents/:type/:id/download_eac' => 'exports#download_eac', :via => [:get]
  match 'agents/:type/:id' => 'agents#show', :via => [:get]
  match 'agents' => 'agents#index', :via => [:get]


  resources :collection_management_records
  match 'collection_management_records/:id' => 'collection_management_records#update', :via => [:post]

  match 'test/shutdown' => 'tests#shutdown', :via => [:get]

  match 'search' => 'search#do_search', :via => [:get]

  match 'resolve/edit' => 'resolver#resolve_edit', :via => [:get]
  match 'resolve/readonly' => 'resolver#resolve_readonly', :via => [:get]

  match 'enumerations/list' => 'enumerations#list', :via => [:get]
  match 'enumerations/delete' => 'enumerations#delete', :via => [:get]
  match 'enumerations/destroy/:id' => 'enumerations#destroy', :via => [:post]
  match 'enumerations/merge/:id' => 'enumerations#merge', :via => [:post]
  resources :enumerations

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     resource do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :resource
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
