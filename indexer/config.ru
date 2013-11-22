require "aspace_gems"
ASpaceGems.setup

require './app/main'

def app
  ArchivesSpaceIndexer
end

map "/" do
  run ArchivesSpaceIndexer
end
