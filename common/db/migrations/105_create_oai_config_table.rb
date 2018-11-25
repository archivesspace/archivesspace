require_relative 'utils'

Sequel.migration do
  up do
    create_table(:oai_config) do
      primary_key :id

      String :oai_repository_name
      String :oai_record_prefix
      String :oai_admin_email

      String :created_by
      String :last_modified_by
      DateTime :create_time
      DateTime :system_mtime
      DateTime :user_mtime
      Integer :lock_version, default: 0
    end
  end

  down do
    drop_table(:oai_config)
  end
end