require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:ark_identifier) do
      add_column(:created_by, String)
      add_column(:last_modified_by, String)
      add_column(:create_time, DateTime)
      add_column(:system_mtime,DateTime)
      add_column(:user_mtime, DateTime)
    end
  end
end