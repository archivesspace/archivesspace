match('/plugins/lcnaf' => 'lcnaf#index', :via => [:get])
match('/plugins/lcnaf/search' => 'lcnaf#search', :via => [:get])
match('/plugins/lcnaf/import' => 'lcnaf#import', :via => [:post])
