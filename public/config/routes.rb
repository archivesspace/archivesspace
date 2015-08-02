ArchivesSpacePublic::Application.routes.draw do

  [AppConfig[:public_proxy_prefix], AppConfig[:public_prefix]].uniq.each do |prefix|

    scope prefix do

      match 'search' => 'search#search', :via => [:get]
      match 'advanced_search' => 'search#advanced_search', :via => [:get]
      match 'tree' => 'records#tree', :via => [:get]
      match 'repositories/:repo_id/resources/:id' => 'records#resource', :via => [:get]
      match 'repositories/:repo_id/digital_objects/:id' => 'records#digital_object', :via => [:get]
      match 'repositories/:repo_id/archival_objects/:id' => 'records#archival_object', :via => [:get]
      match 'repositories/:repo_id/digital_object_components/:id' => 'records#digital_object_component', :via => [:get]
      match 'repositories/:repo_id' => 'search#repository', :via => [:get]
      match 'repositories/:repo_id/classifications/:id' => 'records#classification', :via => [:get]
      match 'repositories/:repo_id/accessions/:id' => 'records#accession', :via => [:get]
      match 'agents/:id' => 'records#agent', :via => [:get]

      match 'repositories' => 'search#repository', :via => [:get]
      match 'subjects/:id' => 'search#subject', :via => [:get]
      root :to => "site#index"

      get 'agents/people/:id', to: redirect('/agents/%{id}?agent_type=agent_person')
      get 'agents/software/:id', to: redirect('/agents/%{id}?agent_type=agent_software')
      get 'agents/families/:id', to: redirect('/agents/%{id}?agent_type=agent_family')
      get 'agents/corporate_entities/:id', to: redirect('/agents/%{id}?agent_type=agent_corporate_entity')
    end
  end
end
