class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/version')
    .description("Get the ArchivesSpace application version")
    .params()
    .permissions([])
    .returns([200, "ArchivesSpace (version)"]) \
  do
    "ArchivesSpace (#{ASConstants.VERSION})"
  end

end
