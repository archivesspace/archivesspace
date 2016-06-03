require_relative 'utils'

Sequel.migration do

  up do

    create_table(:location_function) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :location_id

      DynamicEnum :location_function_type_id, :null => false

      apply_mtime_columns
    end

    alter_table(:location_function) do
      add_foreign_key([:location_id], :location, :key => :id)
    end

    create_editable_enum('location_function_type', ["av_materials", "arrivals", "shared"])

  end

end
