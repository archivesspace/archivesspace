ArchivesSpacePublic::Application.routes.draw do

  [AppConfig[:public_proxy_prefix], AppConfig[:public_prefix]].uniq.each do |prefix|

    scope prefix do

      root "site#index"

      match 'api/repositories/:repo_id/resources/:id' => 'records#resource', :via => [:get]
      match 'api/repositories/:repo_id/archival_objects/:id' => 'records#archival_object', :via => [:get]
      match 'api/repositories/:repo_id/accessions/:id' => 'records#accession', :via => [:get]
      match 'api/repositories/:repo_id/digital_objects/:id' => 'records#digital_object', :via => [:get]
      match 'api/repositories/:repo_id/classifications/:id' => 'records#classification', :via => [:get]



      match 'api/search' => 'search#search', :via => [:get]
      match 'api/advanced_search' => 'search#advanced_search', :via => [:get]

      match 'api/(*url)' => "site#bad_request", :via => [:get]

      get '/(*url)' => "site#index"


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

    end
  end
end
