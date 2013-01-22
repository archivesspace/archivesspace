class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/config/enumerations')
    .description("List all defined enumerations")
    .params()
    .returns([200, "[(:enumeration)]"]) \
  do
    enumerations = Enumeration.as_hash

    json_response(enumerations.map { |name, values| JSONModel(:enumeration).
                               from_hash(:name => name, :values => values).to_hash })
  end


  Endpoint.get('/config/enumerations/:name')
    .description("List a single enumeration")
    .params(["name", /\A[a-z_]+\z/, "The name of the enumeration"])
    .returns([200, "(:enumeration)"]) \
  do
    json_response(JSONModel(:enumeration).from_hash(:name => params[:name],
                                                    :values => BackendEnumSource.values_for(params[:name])))
  end

end
