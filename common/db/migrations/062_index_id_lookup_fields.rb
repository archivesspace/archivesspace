require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_index(:ref_id)
      add_index(:component_id)
    end

    alter_table(:digital_object_component) do
      add_index(:component_id)
    end
  end

  down do
    alter_table(:archival_object) do
      drop_index(:ref_id)
      drop_index(:component_id)
    end

    alter_table(:digital_object_component) do
      drop_index(:component_id)
    end
  end

end
