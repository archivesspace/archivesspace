class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/config/enumerations')
    .description("List all defined enumerations")
    .params()
    .returns([200, "[(:enumeration)]"]) \
  do
    handle_unlimited_listing(Enumeration)
  end


  Endpoint.post('/config/enumerations')
    .description("Create an enumeration")
    .params(["enumeration", JSONModel(:enumeration), "The enumeration to create", :body => true])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Enumeration, :enumeration)
  end


  Endpoint.post('/config/enumerations/:enum_id')
    .description("Update an enumeration")
    .params(["enum_id", Integer, "The ID of the enumeration to update"],
            ["enumeration", JSONModel(:enumeration), "The enumeration to update", :body => true])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Enumeration, :enum_id, :enumeration)
  end


  Endpoint.get('/config/enumerations/:enum_id')
    .description("Get an Enumeration")
    .params(["enum_id", Integer, "The ID of the enumeration to retrieve"])
    .returns([200, "(:enumeration)"]) \
  do
     json_response(Enumeration.to_jsonmodel(params[:enum_id]).to_hash)
  end

end
