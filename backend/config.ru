require 'rubygems'
# bundled_gems = Gem.path.find_all { |path| path =~ /WEB-INF/ }
# 
# # Blow away any paths we've picked up from the environment.
# ENV['GEM_HOME'] = nil
# ENV['GEM_PATH'] = nil
# 
# Gem.use_paths(nil, bundled_gems)

require './app/main'

def app
  ArchivesSpaceService
end

map "/" do
  run ArchivesSpaceService
end
