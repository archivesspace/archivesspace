class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/system/info')
  .description("Get the diagnostic information about the system")
  .permissions([:administer_system])
  .returns([200, "(:repository)"],
           [403, "Access Denied"]) \
  do
    sys_info = ASUtils.get_diagnostics.reject { |k, v| k == :exception }
    sys_info[:db_info]= DB.sysinfo

    schema = Solr::Schema.new(AppConfig[:solr_url])
    config = Solr::Solrconfig.new(AppConfig[:solr_url])
    sys_info[:solr_info] = {
      schema_checksum_internal: schema.internal_checksum,
      schema_checksum_external: schema.external_checksum,
      solrconfig_checksum_internal: config.internal_checksum,
      solrconfig_checksum_external: config.external_checksum,
    }
    json_response(sys_info)
  end

  Endpoint.get('/system/log')
  .description("Get the log information and start the 15 second log recorder")
  .permissions([:administer_system])
  .returns([200, "String"],
           [403, "Access Denied"]) \
  do
    [200, {}, Log.backlog ]
  end

  Endpoint.get('/system/events')
  .description("Get the systems events that have been logged for this install")
  .permissions([:administer_system])
  .returns([200, "String"],
           [403, "Access Denied"]) \
  do
    [200, {}, SystemEvent.all.collect { |a| a.values }.to_json ]
  end

end
