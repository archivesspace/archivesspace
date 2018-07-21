require_relative 'utils'

Sequel.migration do

  up do
    create_table(:custom_report_template) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      String :name, :null => false, :unique => true
      String :description
      TextField :data, :null => false

      apply_mtime_columns
    end
  end
end
