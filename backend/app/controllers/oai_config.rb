class ArchivesSpaceService < Sinatra::Base

  # get oai_config record
  Endpoint.get('/oai_config')
    .description("Get a list of OAI Config records")
    .permissions([])
    .returns([200, "[(:oai_config)]"]) \
  do
    handle_unlimited_listing(OAIConfig)
  end
end
