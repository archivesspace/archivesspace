ArchivesSpace::Application.routes.draw do
  scope AppConfig[:frontend_proxy_prefix] do
    match('/plugins/lcnaf' => 'lcnaf#index', :via => [:get])
    match('/plugins/lcnaf/search' => 'lcnaf#search', :via => [:get])
    match('/plugins/lcnaf/import' => 'lcnaf#import', :via => [:post])
  end
end
