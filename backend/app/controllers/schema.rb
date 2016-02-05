class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/schemas')
    .description("Get all ArchivesSpace schemas")
    .params()
    .permissions([])
    .returns([200, "ArchivesSpace (schemas)"]) \
  do
    schemas = Hash[ models.keys.map { |schema| [schema, JSONModel(schema.to_sym).schema] } ]
    json_response( schemas )
  end

  Endpoint.get('/schemas/:schema')
    .description("Get an ArchivesSpace schema")
    .params(["schema", String, "Schema name to retrieve"])
    .permissions([])
    .returns([200, "ArchivesSpace (:schema)"],
             [404, "Schema not found"]) \
  do
    schema = params[:schema]
    if models.has_key? schema
      json_response( JSONModel(schema.to_sym).schema )
    else
      raise NotFoundException.new
    end
  end

end