Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope AppConfig[:public_proxy_prefix] do
    root to: "welcome#show"

    get '/welcome', to: 'welcome#show'
    
    # I don't think this is used anywhere... 
    post '/cite', to: 'cite#show'
    
    get 'objects/search' => 'objects#search'
    get 'objects' => 'objects#index'
    
    get 'accessions/search' => 'accessions#search'
    get 'accessions' => 'accessions#index'
    
    get 'classifications/search' => 'classifications#search'
    get 'classifications' => 'classifications#index'
    
    post 'fill_request' => 'requests#make_request'
    
    get 'subjects/search' => 'subjects#search'
    get "subjects/:id" => 'subjects#show'
    get 'subjects' => 'subjects#index'
    
    get 'agents/search' => 'agents#search'
    get "agents/:eid/:id" => 'agents#show'
    get 'agents' => 'agents#index'

    get  "repositories/:rid/top_containers/:id" => 'containers#show'
    get 'repositories/resources' => 'resources#index'
    
    get "repositories/:rid/accessions" => 'accessions#index'
    get  "repositories/:rid/accessions/:id" => 'accessions#show'
 
    post "repositories/:rid/accessions/:id/request" => 'objects#request_showing'
    get "repositories/:rid/accessions/:id/request" => 'objects#request_showing'
    
    post "repositories/:rid/archival_objects/:id/request" => 'objects#request_showing'
    get "repositories/:rid/archival_objects/:id/request" => 'objects#request_showing'
    
    get  "repositories/:rid/classifications/:id" => 'classifications#show'
    get  "repositories/:rid/classification_terms/:id" => 'classifications#term'
    get  "repositories/:repo_id/resources/:id/search"  => 'resources#search'
    get "repositories/:rid/resources/:id"  => 'resources#show'
    
    post "repositories/:rid/resources/:id/pdf"  => 'pdf#resource'
    
    get "repositories/:rid/resources/:id/inventory"  => 'resources#inventory'
    get 'repositories/:rid/resources/:id/resolve/:ref_id' => 'resources#resolve'
   
    get "repositories/:rid/:obj_type/:id" => 'objects#show'
    
    get  "repositories/:rid/classifications/" => 'classifications#index'
    
    get "repositories/:rid/resources" => 'resources#index'
    get  "repositories/:rid/search" => 'search#search'
    get "repositories/:rid/agents" => 'agents#index'
    get "repositories/:rid/subjects" => 'subjects#index'
    get "repositories/:rid/objects" => 'objects#index'
    get "repositories/:rid/digital_objects" => 'objects#index'
    get "repositories/:rid/records" => 'objects#index'
    get "repositories/:id" => 'repositories#show'

    get "repositories/:rid/resources/:id/collection_organization"  => 'resources#infinite'
    get "repositories/:rid/resources/:id/infinite/waypoints"  => 'resources#waypoints'

    get "repositories/:rid/resources/:id/tree/root"  => 'resources#tree_root'
    get "repositories/:rid/resources/:id/tree/waypoint"  => 'resources#tree_waypoint'
    get "repositories/:rid/resources/:id/tree/node"  => 'resources#tree_node'
    get "repositories/:rid/resources/:id/tree/node_from_root"  => 'resources#tree_node_from_root'

    get "repositories/:rid/digital_objects/:id/tree/root"  => 'digital_objects#tree_root'
    get "repositories/:rid/digital_objects/:id/tree/waypoint"  => 'digital_objects#tree_waypoint'
    get "repositories/:rid/digital_objects/:id/tree/node"  => 'digital_objects#tree_node'
    get "repositories/:rid/digital_objects/:id/tree/node_from_root"  => 'digital_objects#tree_node_from_root'

    get "repositories/:rid/classifications/:id/tree/root"  => 'classifications#tree_root'
    get "repositories/:rid/classifications/:id/tree/waypoint"  => 'classifications#tree_waypoint'
    get "repositories/:rid/classifications/:id/tree/node"  => 'classifications#tree_node'
    get "repositories/:rid/classifications/:id/tree/node_from_root"  => 'classifications#tree_node_from_root'

    get '/repositories', to: 'repositories#index'
    get '/search', to: 'search#search'
  end
end
