class ArchivesSpaceService < Sinatra::Base

  # get oai_config record
  Endpoint.get('/oai_config')
    .description("Get the OAI Config record")
    .permissions([])
    .returns([200, "[(:oai_config)]"]) \
  do
    handle_unlimited_listing(OAIConfig)
  end

  # update oai_config record
  Endpoint.post('/oai_config')
    .description("Update the OAI config record")
    .params(["oai_config",
             JSONModel(:oai_config),
             "The updated record",
             :body => true])
    .permissions([:create_repository])
    .returns([200, :updated]) \
  do
    oc = OAIConfig.first
    json = params[:oai_config]

    puts "++++++++++++++++++++++++++++"
    puts "IN BACKEND"
    puts "json: " + json.inspect
    puts "oc: " + oc.inspect
    puts "thing: " + json["oai_repository_name"]

    oc.update(:oai_repository_name => json["oai_repository_name"], 
              :oai_admin_email     => json["oai_admin_email"], 
              :oai_record_prefix   => json["oai_record_prefix"]) 

    updated_response(oc, json)
  end
end
