require_relative 'utils'

Sequel.migration do
  $stderr.puts "Creating new agents tables"
  up do
    alter_table(:name_family) do
      add_column(:family_type, String)
      add_column(:location, String)

      add_column(:language_id, Integer)
      add_column(:script_id, Integer)
      add_column(:transliteration_id, Integer)
    end

    alter_table(:name_corporate_entity) do
      add_column(:location, String)
      add_column(:jurisdiction, Integer, :default => 0)
      add_column(:conference_meeting, Integer, :default => 0)

      add_column(:language_id, Integer)
      add_column(:script_id, Integer)
      add_column(:transliteration_id, Integer)
    end

    alter_table(:name_person) do
      add_column(:language_id, Integer)
      add_column(:script_id, Integer)
      add_column(:transliteration_id, Integer)
    end

    alter_table(:name_software) do
      add_column(:language_id, Integer)
      add_column(:script_id, Integer)
      add_column(:transliteration_id, Integer)
    end

    alter_table(:note) do
      add_column(:agent_topic_id, Integer, :null => true)
      add_column(:agent_place_id, Integer, :null => true)
      add_column(:agent_occupation_id, Integer, :null => true)
      add_column(:agent_function_id, Integer, :null => true)
      add_column(:agent_gender_id, Integer, :null => true)
      add_column(:used_language_id, Integer, :null => true)
    end

    alter_table(:agent_contact) do
      drop_column(:note)
    end

    alter_table(:note) do
      add_column(:agent_contact_id, Integer, :null => true)
    end
  end
end
