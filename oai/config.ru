require "aspace_gems"
ASpaceGems.setup

require './app/main'

def app
  ArchivesSpaceOAIServer
end

map "/" do
  run ArchivesSpaceOAIServer
end
