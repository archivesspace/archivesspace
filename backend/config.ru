require "aspace_gems"
ASpaceGems.setup

require './app/main'

def app
  ArchivesSpaceService
end

map "/" do
  run ArchivesSpaceService
end
