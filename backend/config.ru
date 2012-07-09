require 'rubygems'
require './app/main'

def app
  ArchivesSpaceService
end

map "/" do
  run ArchivesSpaceService
end
