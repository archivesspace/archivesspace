require './app/main'

def app
  ArchivesSpaceIndexer
end

map "/" do
  run ArchivesSpaceIndexer
end
