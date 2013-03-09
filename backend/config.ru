require 'rubygems'
bundled_gems = Gem.path.find_all { |path| path =~ /WEB-INF/ }

Gem.use_paths(nil, bundled_gems)

require './app/main'

def app
  ArchivesSpaceService
end

map "/" do
  run ArchivesSpaceService
end
