ArchivesSpacePublic::Application.routes.draw do
  match ':repo/search' => 'site#search', :via => [:get]
  match ':repo/index' => 'site#index', :via => [:get]
  match ':repo/' => 'site#index', :via => [:get]
  root :to => "site#index"
end
