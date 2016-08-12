Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/', to: 'welcome#show' #'index#index'
  get '/welcome', to: 'welcome#show'
  get "repositories/:rid/resources/:id"  => 'resources#show'
  get "repositories/:rid/resources" => 'resources#index'
  get "repositories/:id/:type" => 'repositories#sublist'
  post "repositories/:id/:type" => 'repositories#sublist'
  get "repositories/:id" => 'repositories#show'
  get '/repositories', to: 'repositories#index'
  get '/search', to: 'search#search'
end
