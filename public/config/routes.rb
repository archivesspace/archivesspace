ArchivesSpacePublic::Application.routes.draw do
  match 'search' => 'site#search', :via => [:get]
  match 'advanced_search' => 'site#advanced_search', :via => [:get]
  match 'repositories/:repo_id/resources/:id' => 'site#resource', :via => [:get]
  match 'repositories/:repo_id/digital_objects/:id' => 'site#digital_object', :via => [:get]
  match 'repositories/:repo_id/archival_objects/:id' => 'site#archival_object', :via => [:get]
  match 'repositories/:repo_id/digital_object_components/:id' => 'site#digital_object_component', :via => [:get]
  match 'repositories/:repo_id' => 'site#repository', :via => [:get]
  match 'repositories' => 'site#repository', :via => [:get]
  match 'subjects/:id' => 'site#subject', :via => [:get]
  match 'locations/:id' => 'site#location', :via => [:get]
  root :to => "site#index"
end
