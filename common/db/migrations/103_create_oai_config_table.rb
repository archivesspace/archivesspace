require_relative 'utils'

Sequel.migration do
  up do
    create_table(:oai_config) do
      primary_key :id

      String :oai_repository_name
      String :oai_record_prefix
      String :oai_admin_email
    end
  end

  down do
    drop_table(:oai_config)
  end
end