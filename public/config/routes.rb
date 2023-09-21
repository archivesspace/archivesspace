Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope AppConfig[:public_proxy_prefix] do
    root to: "welcome#show"

    get '/welcome', to: 'welcome#show'

    if AppConfig[:arks_enabled]
      get '/ark:/*ark_id' => 'ark_name#show'
    end

    # I don't think this is used anywhere...
    post '/cite', to: 'cite#show'

    # RESOURCES
    if AppConfig[:use_human_readable_urls]
      get "resources/:slug_or_id" => 'resources#show'
      get "repositories/:repo_slug/resources/:slug_or_id" => 'resources#show'
    end

    get  'repositories/resources' => 'resources#index'
    get  "repositories/:repo_id/resources/:id/search" => 'resources#search'
    get  "repositories/:rid/resources/:id" => 'resources#show'
    post "repositories/:rid/resources/:id/pdf" => 'pdf#resource'
    get  "repositories/:rid/resources/:id/digitized" => 'resources#digitized'
    get  "repositories/:rid/resources/:id/inventory" => 'resources#inventory'
    get  'repositories/:rid/resources/:id/resolve/:ref_id' => 'resources#resolve'
    get  "repositories/:rid/resources" => 'resources#index'
    get  "repositories/:rid/resources/:id/collection_organization" => 'resources#infinite'
    get  "repositories/:rid/resources/:id/infinite/waypoints" => 'resources#waypoints'
    get  "repositories/:rid/resources/:id/tree/root" => 'resources#tree_root'
    get  "repositories/:rid/resources/:id/tree/waypoint" => 'resources#tree_waypoint'
    get  "repositories/:rid/resources/:id/tree/node" => 'resources#tree_node'
    get  "repositories/:rid/resources/:id/tree/node_from_root" => 'resources#tree_node_from_root'

    #ACCESSIONS
    if AppConfig[:use_human_readable_urls]
      get "accessions/:slug_or_id" => 'accessions#show'
      get "repositories/:repo_slug/accessions/:slug_or_id" => 'accessions#show'
    end

    get  'accessions/search' => 'accessions#search'
    get  'accessions' => 'accessions#index'
    get  "repositories/:rid/accessions" => 'accessions#index'
    get  "repositories/:rid/accessions/:id" => 'accessions#show'

    #DIGITAL OBJECTS
    get "repositories/:rid/digital_objects" => 'objects#index'
    get "repositories/:rid/digital_objects/:id/tree/root" => 'digital_objects#tree_root'
    get "repositories/:rid/digital_objects/:id/tree/waypoint" => 'digital_objects#tree_waypoint'
    get "repositories/:rid/digital_objects/:id/tree/node" => 'digital_objects#tree_node'
    get "repositories/:rid/digital_objects/:id/tree/node_from_root" => 'digital_objects#tree_node_from_root'

    #CLASSIFICATIONS
    if AppConfig[:use_human_readable_urls]
      get "classifications/:slug_or_id" => 'classifications#show'
      get "repositories/:repo_slug/classifications/:slug_or_id" => 'classifications#show'
    end

    get 'classifications/search' => 'classifications#search'
    get 'classifications' => 'classifications#index'
    get "repositories/:rid/classifications/:id" => 'classifications#show'
    get "repositories/:rid/classifications/" => 'classifications#index'

    get "repositories/:rid/classifications/:id/tree/root" => 'classifications#tree_root'
    get "repositories/:rid/classifications/:id/tree/waypoint" => 'classifications#tree_waypoint'
    get "repositories/:rid/classifications/:id/tree/node" => 'classifications#tree_node'
    get "repositories/:rid/classifications/:id/tree/node_from_root" => 'classifications#tree_node_from_root'

    #CLASSIFICATION TERMS
    get "repositories/:repo_slug/classification_terms/:slug_or_id" => 'classifications#term'
    if AppConfig[:use_human_readable_urls]
      get "classification_terms/:slug_or_id" => 'classifications#term'
    end

    #SUBJECTS
    get "subjects/:slug_or_id" => 'subjects#show'
    get 'subjects/search' => 'subjects#search'
    get 'subjects' => 'subjects#index'
    get "repositories/:rid/subjects" => 'subjects#index'

    #AGENTS
    if AppConfig[:use_human_readable_urls]
      get "agents/:slug_or_id" => 'agents#show'
    end

    get 'agents/search' => 'agents#search'
    get "agents/:eid/:id" => 'agents#show'
    get 'agents' => 'agents#index'
    get "repositories/:rid/agents" => 'agents#index'

    #REPOSITORIES
    get "repositories/:slug_or_id" => 'repositories#show'
    get '/repositories', to: 'repositories#index'
    get "repositories/:rid/search" => 'search#search'

    #TOP CONTAINERS
    get "repositories/:rid/top_containers/:id" => 'containers#show'

    # SLUGGED OBJECTS (# ARCHIVAL OBJECTS, DIGITAL OBJECTS, DIGITAL OBJECT COMPONENTS)
    if AppConfig[:use_human_readable_urls]
      get ":obj_type/:slug_or_id" => 'objects#show'
      get "repositories/:repo_slug/:obj_type/:slug_or_id" => 'objects#show'
    end

    #OBJECTS (generic, pass in the object_type as a param)
    get 'objects/search' => 'objects#search'
    get 'objects' => 'objects#index'
    get "repositories/:rid/:obj_type/:id" => 'objects#show'
    get "repositories/:rid/objects" => 'objects#index'
    get "repositories/:rid/records" => 'objects#index'

    # OTHER (NOT SLUGGED YET)

    post 'fill_request' => 'requests#make_request'

    get '/search', to: 'search#search'

    post '/locale', to: 'locales#locale'
  end
end
