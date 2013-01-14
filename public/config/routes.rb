ArchivesSpacePublic::Application.routes.draw do
  match 'search' => 'site#search', :via => [:get]
  root :to => "site#index"
end
