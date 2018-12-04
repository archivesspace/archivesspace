require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:agent_person) do
    	add_column(:slug, String)
      add_column(:is_slug_auto, Integer)
    end

    alter_table(:agent_family) do
    	add_column(:slug, String)
      add_column(:is_slug_auto, Integer)
    end

    alter_table(:agent_software) do
    	add_column(:slug, String)
      add_column(:is_slug_auto, Integer)
    end

    alter_table(:agent_corporate_entity) do
    	add_column(:slug, String)
      add_column(:is_slug_auto, Integer)
    end
  end
end