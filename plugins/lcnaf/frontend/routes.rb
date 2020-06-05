ArchivesSpace::Application.routes.draw do

  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|

    scope prefix do
      match('/plugins/lcnaf' => 'lcnaf#index', :via => [:get])
      match('/plugins/lcnaf/search' => 'lcnaf#search', :via => [:get])
      match('/plugins/lcnaf/import' => 'lcnaf#import', :via => [:post])
    end
  end
end
