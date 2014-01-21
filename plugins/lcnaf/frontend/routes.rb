ArchivesSpace::Application.routes.draw do

  match('/plugins/lcnaf/search' => 'lcnaf_search#search', :via => [:get])

end
