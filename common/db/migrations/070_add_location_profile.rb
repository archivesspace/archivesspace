require_relative 'utils'

Sequel.migration do

  up do
    create_table(:location_profile) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :name

      DynamicEnum :dimension_units_id

      String :height
      String :width
      String :depth

      apply_mtime_columns
    end

    alter_table(:location_profile) do
      add_unique_constraint(:name, :name => "location_profile_name_uniq")
    end

    create_table(:location_profile_rlshp) do
      primary_key :id

      Integer :location_id
      Integer :location_profile_id
      Integer :aspace_relationship_position

      Integer :suppressed, :null => false, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:location_profile_rlshp) do
      add_foreign_key([:location_id], :location, :key => :id)
      add_foreign_key([:location_profile_id], :location_profile, :key => :id)
    end
  end
end
