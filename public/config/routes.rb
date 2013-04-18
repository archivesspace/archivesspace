ArchivesSpacePublic::Application.routes.draw do
  match 'search' => 'search#search', :via => [:get]
  match 'advanced_search' => 'search#advanced_search', :via => [:get]
  match 'repositories/:repo_id/resources/:id' => 'records#resource', :via => [:get]
  match 'repositories/:repo_id/digital_objects/:id' => 'records#digital_object', :via => [:get]
  match 'repositories/:repo_id/archival_objects/:id' => 'records#archival_object', :via => [:get]
  match 'repositories/:repo_id/digital_object_components/:id' => 'records#digital_object_component', :via => [:get]
  match 'repositories/:repo_id' => 'search#repository', :via => [:get]
  match 'repositories' => 'search#repository', :via => [:get]
  match 'subjects/:id' => 'search#subject', :via => [:get]
  root :to => "site#index"
end
