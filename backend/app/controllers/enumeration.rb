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
    .permissions([:update_enumeration_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Enumeration, params[:enumeration])
  end


  Endpoint.post('/config/enumerations/migration')
    .description("Migrate all records from one value to another")
    .example('shell') do
    <<~SHELL
    curl -H 'Content-Type: application/json' \\
        -H "X-ArchivesSpace-Session: $SESSION" \\
        -d '{"enum_uri": "/config/enumerations/17", "from": "sir", "to": "mr"}' \\
        "http://localhost:8089/config/enumerations/migration"
    SHELL
    end
    .example('python') do
    <<~PYTHON
    from asnake.client import ASnakeClient

    client = ASnakeClient()
    client.authorize()

    client.post('/config/enumerations/migration',
                json={
                    'enum_uri': '/config/enumerations/17',
                    'from': 'sir', #value to be deleted
                    'to': 'mr' #value to merge into
                    }
                )
    PYTHON
    end
    .params(["migration", JSONModel(:enumeration_migration), "The migration request", :body => true])
    .permissions([:update_enumeration_record])
    .returns([200, :updated],
             [400, :error],
             [404, "Not found"]) \
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
    .permissions([:update_enumeration_record])
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

  Endpoint.get('/config/enumerations/names/:enum_name')
    .description("Get an Enumeration by Name")
    .params(["enum_name", String, "The name of the enumeration to retrieve"])
    .permissions([])
    .returns([200, "(:enumeration)"]) \
  do
     json_response(Enumeration.to_jsonmodel(params[:enum_name], query: "name"))
  end

  Endpoint.get('/config/enumeration_values/:enum_val_id')
    .description("Get an Enumeration Value")
    .params(["enum_val_id", Integer, "The ID of the enumeration value to retrieve"])
    .permissions([])
    .returns([200, "(:enumeration_value)"]) \
  do
     json_response(EnumerationValue.to_jsonmodel(params[:enum_val_id]))
  end

  Endpoint.post('/config/enumeration_values/:enum_val_id')
    .description("Update an enumeration value")
    .params(["enum_val_id", Integer, "The ID of the enumeration value to update"],
            ["enumeration_value", JSONModel(:enumeration_value), "The enumeration value to update", :body => true])
    .permissions([:update_enumeration_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(EnumerationValue, params[:enum_val_id], params[:enumeration_value])
  end

  Endpoint.post('/config/enumeration_values/:enum_val_id/position')
    .description("Update the position of an ennumeration value")
    .params(["enum_val_id", Integer, "The ID of the enumeration value to update"],
            ["position", Integer, "The target position in the value list"])
    .permissions([:update_enumeration_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    obj = EnumerationValue.get_or_die(params[:enum_val_id])
    obj.update_position_only(params[:position])
    updated_response( obj.refresh )
  end

  Endpoint.post('/config/enumeration_values/:enum_val_id/suppressed')
    .description("Suppress this value")
    .params(["enum_val_id", Integer, "The ID of the enumeration value to update"],
            ["suppressed", BooleanParam, "Suppression state"])
    .permissions([:update_enumeration_record])
    .returns([200, :suppressed],
             [400, :error]) \
  do
    sup_state = EnumerationValue.handle_suppressed([ params[:enum_val_id] ], params[:suppressed])
    suppressed_response(params[:enum_val_id], sup_state)
  end

end
