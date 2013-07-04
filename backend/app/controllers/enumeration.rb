class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/config/enumerations')
    .description("List all defined enumerations")
    .params()
    .permissions([])
    .returns([200, "[(:enumeration)]"]) \
  do
    handle_unlimited_listing(Enumeration)
  end


  Endpoint.post('/config/enumerations')
    .description("Create an enumeration")
    .params(["enumeration", JSONModel(:enumeration), "The record to create", :body => true])
    .permissions([:system_config])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Enumeration, params[:enumeration])
  end


  Endpoint.post('/config/enumerations/migration')
    .description("Migrate all records from using one value to another")
    .params(["migration", JSONModel(:enumeration_migration), "The migration request", :body => true])
    .permissions([:system_config])
    .returns([200, :updated],
             [400, :error]) \
  do
    enum_id = JSONModel(:enumeration).id_for(params[:migration].enum_uri)
    enum = Enumeration.get_or_die(enum_id)

    enum.migrate(params[:migration].from, params[:migration].to)

    json_response(Enumeration.to_jsonmodel(enum_id))
  end


  Endpoint.post('/config/enumerations/:enum_id')
    .description("Update an enumeration")
    .params(["enum_id", Integer, "The ID of the enumeration to update"],
            ["enumeration", JSONModel(:enumeration), "The enumeration to update", :body => true])
    .permissions([:system_config])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Enumeration, params[:enum_id], params[:enumeration])
  end


  Endpoint.get('/config/enumerations/:enum_id')
    .description("Get an Enumeration")
    .params(["enum_id", Integer, "The ID of the enumeration to retrieve"])
    .permissions([])
    .returns([200, "(:enumeration)"]) \
  do
     json_response(Enumeration.to_jsonmodel(params[:enum_id]))
  end

end
