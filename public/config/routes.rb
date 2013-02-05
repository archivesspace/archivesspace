ArchivesSpacePublic::Application.routes.draw do
  match 'search' => 'site#search', :via => [:get]
  match 'repositories/:repo_id/resources/:id' => 'site#resource', :via => [:get]
  match 'repositories/:repo_id/archival_objects/:id' => 'site#archival_object', :via => [:get]
  match 'repositories/:repo_id' => 'site#repository', :via => [:get]
  match 'repositories' => 'site#repository', :via => [:get]
  root :to => "site#index"
end
