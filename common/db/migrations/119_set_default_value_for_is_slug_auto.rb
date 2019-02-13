require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:repository) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:resource) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:subject) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:digital_object) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:accession) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:classification) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:agent_person) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:agent_family) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:agent_software) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:agent_corporate_entity) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:archival_object) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:digital_object_component) do
      set_column_default :is_slug_auto, 1
    end

    alter_table(:classification_term) do
      set_column_default :is_slug_auto, 1
    end
  end
end