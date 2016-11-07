Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/', to: 'welcome#show' #'index#index'
  get '/welcome', to: 'welcome#show'
  post '/cite', to: 'cite#show'
  get "subjects/:id" => 'subjects#show'
  get "agents/:eid/:id" => 'agents#show'
  get 'repositories/resources' => 'resources#index'
  get  "repositories/:rid/accessions/:id" => 'accessions#show'
  get  "repositories/:rid/classifications/:id" => 'classifications#show'
  get  "repositories/:repo_id/resources/:id/search"  => 'resources#search'
  get "repositories/:rid/resources/:id"  => 'resources#show'

  get "repositories/:rid/:obj_type/:id" => 'objects#show'
  get "repositories/:rid/resources" => 'resources#index'
  get  "repositories/:rid/search" => 'repositories#search'
  post "repositories/:rid/search" => 'repositories#search'
  get "repositories/:id/:type" => 'repositories#sublist'
  post "repositories/:id/:type" => 'repositories#sublist'
  get "repositories/:id" => 'repositories#show'
  post "repositories/:id" => 'repositories#show'
  
  get '/repositories', to: 'repositories#index'
  get '/search', to: 'search#search'
end
