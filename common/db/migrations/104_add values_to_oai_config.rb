require_relative 'utils'

# populates the oai_config table with existing config values, or default values if no existing values are present.
# resources, accessions, and digital objects

Sequel.migration do
  up do
    oai_repository_name = AppConfig[:oai_repository_name] || 'ArchivesSpace OAI Provider'
    oai_record_prefix   = AppConfig[:oai_record_prefix] || 'oai:archivesspace'
    oai_admin_email     = AppConfig[:oai_admin_email] || 'admin@example.com'
  
  
    self[:oai_config].insert(:oai_repository_name => oai_repository_name,
                             :oai_record_prefix   => oai_record_prefix,
                             :oai_admin_email     => oai_admin_email)
  end

  down do
    self[:oai_config].select.first.delete
  end

end
