require_relative 'utils'

# populates the oai_config table with existing config values, or default values if no existing values are present.
# resources, accessions, and digital objects

Sequel.migration do
  up do
    $stderr.puts("Adding values OAI config table")
    oai_repository_name = AppConfig.has_key?(:oai_repository_name) ? AppConfig[:oai_repository_name] : 'ArchivesSpace OAI Provider'
    oai_record_prefix   = AppConfig.has_key?(:oai_record_prefix) ? AppConfig[:oai_record_prefix] : 'oai:archivesspace'
    oai_admin_email     = AppConfig.has_key?(:oai_admin_email) ? AppConfig[:oai_admin_email] : 'admin@example.com'


    self[:oai_config].insert(:oai_repository_name => oai_repository_name,
                             :oai_record_prefix   => oai_record_prefix,
                             :oai_admin_email     => oai_admin_email,
                             :lock_version        => 0,
                             :create_time         => Time.now,
                             :system_mtime        => Time.now,
                             :user_mtime          => Time.now,
                             :created_by          => "admin")
  end

  down do
  end

end
