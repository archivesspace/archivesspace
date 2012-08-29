ArchivesSpace::Application.routes.draw do
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

  resources :users

  resources :groups
  match 'groups/:id' => 'groups#update', :via => [:post]

  resources :accessions
  resources :archival_objects
  match 'archival_objects/:id' => 'archival_objects#update', :via => [:post]

  resources :resources
  match 'resources/:id/update_tree' => 'resources#update_tree', :via => [:post]
  match 'resources/:id/tree' => 'resources#tree', :via => [:get]
  match 'resources/:id' => 'resources#update', :via => [:post]

  match 'subjects/list' => 'subjects#list', :via => [:get]
  resources :subjects
  match 'subjects/:id' => 'subjects#update', :via => [:post]

  match 'agents/contact_form' => 'agents#contact_form', :via => [:get]
  match 'agents/:type/name_form' => 'agents#name_form', :via => [:get]
  match 'agents/:type/create' => 'agents#create', :via => [:post]
  match 'agents/:type/new' => 'agents#new', :via => [:get]
  match 'agents/:type/:id/edit' => 'agents#edit', :via => [:get]
  match 'agents/:type/:id/update' => 'agents#update', :via => [:post]
  match 'agents/:type/:id' => 'agents#show', :via => [:get]
  match 'agents' => 'agents#index', :via => [:get]

  match 'test/shutdown' => 'tests#shutdown', :via => [:get]


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
