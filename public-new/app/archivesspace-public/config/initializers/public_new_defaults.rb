#require "memoryleak"
#require 'pp'
module PublicNewDefaults
#  pp "initializing resources"

  Repository.set_repos(ArchivesSpaceClient.new.list_repositories)
#  MemoryLeak::Resources.define(:repository, proc { ArchivesSpaceClient.new.list_repositories }, 60)
#pp MemoryLeak::Resources.get(:repository)

end
