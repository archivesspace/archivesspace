ArchivesSpace::Application.routes.draw do

  match('/plugins/lcnaf' => 'lcnaf_search#index', :via => [:get])
  match('/plugins/lcnaf/search' => 'lcnaf_search#search', :via => [:get])
  match('/plugins/lcnaf/import' => 'lcnaf_search#import', :via => [:post])

end
