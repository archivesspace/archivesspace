require_relative 'utils'

# TODO: Remove both this migration and 119. 

# This migration exists only to reset any test instances back to a default value of 0 for is_slug_auto.

Sequel.migration do
  up do
    alter_table(:repository) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:resource) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:subject) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:digital_object) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:accession) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:classification) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:agent_person) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:agent_family) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:agent_software) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:agent_corporate_entity) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:archival_object) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:digital_object_component) do
      set_column_default :is_slug_auto, 0
    end

    alter_table(:classification_term) do
      set_column_default :is_slug_auto, 0
    end
  end
end