require_relative 'utils'

def migrate_contact_notes(ac_notes)
  # Find all agent_contact notes
  ac_notes.each do |ac|
    self[:note].insert(
      :notes_json_schema_version => 1,
      :notes => blobify(self, JSON.generate({
                                  'jsonmodel_type' => 'note_contact_note',
                                  'date_of_contact' => "Before #{Time.now.strftime("%Y-%m-%d")}",
                                  'contact_notes' => ac[:note],
                                  'persistent_id' => SecureRandom.hex
                                })),
      :last_modified_by => ac[:last_modified_by],
      :created_by => 'admin',
      :create_time => ac[:create_time],
      :system_mtime => Time.now,
      :user_mtime => ac[:user_mtime],
      :agent_contact_id => ac[:id]
      )

    self[:agent_contact].where(id: ac[:id]).update(note: nil)

  end
end

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
      add_column(:agent_contact_id, Integer, :null => true)
    end

    ac_notes = self[:agent_contact].filter(Sequel.~(:note => nil))
    migrate_contact_notes(ac_notes) unless ac_notes.count == 0

    # Attempt to delete old agent contact notes
    if ac_notes.count == 0
      alter_table(:agent_contact) do
        drop_column(:note)
      end
    else
      $stderr.puts("WARNING: we tried to drop the column " +
                   "'agent_contact.note' as a part of " +
                   "migration 142_update_existing_tables_for_agents.rb but " +
                   "there's still data in it.  Please contact " +
                   "support as your migration may be incomplete.")
    end

  end
end
