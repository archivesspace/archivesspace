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
    update_oai_config(params)
  end

  # update oai_config record 
  # same as above, but update the single record in table 
  # no matter what ID is passed in 
  Endpoint.post('/oai_config/:id')
    .description("Update the OAI config record")
    .params(["oai_config",
             JSONModel(:oai_config),
             "The updated record",
             :body => true])
    .permissions([:create_repository])
    .returns([200, :updated]) \
  do
    update_oai_config(params)
  end

  def update_oai_config(params)
    oc = OAIConfig.first
    json = params[:oai_config]

    oc.update(:oai_repository_name     => json["oai_repository_name"], 
              :oai_admin_email         => json["oai_admin_email"], 
              :oai_record_prefix       => json["oai_record_prefix"],
              :repo_set_codes          => json["repo_set_codes"],
              :sponsor_set_names       => json["sponsor_set_names"],
              :repo_set_description    => json["repo_set_description"],
              :sponsor_set_description => json["sponsor_set_description"],
              :repo_set_name           => json["repo_set_name"],
              :sponsor_set_name        => json["sponsor_set_name"]
              ) 

    updated_response(oc, json)
  end
end
