require_relative 'utils'

Sequel.migration do

  up do
    create_table(:note) do
      primary_key :id

      Integer :lock_version, :default => 1, :null => false

      Integer :resource_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true
      Integer :agent_person_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_software_id, :null => true

      Integer :publish

      Integer :notes_json_schema_version, :null => false
      MediumBlobField :notes, :null => false

      apply_mtime_columns
    end

    alter_table(:note) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end


    TABLES_WITH_NOTES = [:resource, :archival_object, :digital_object, :digital_object_component,
                         :agent_person, :agent_corporate_entity, :agent_family, :agent_software]

    TABLES_WITH_NOTES.each do |table|
      $stderr.puts("Migrating notes for records of type #{table}")
      migrated_count = 0
      fk_column = "#{table}_id".intern

      self[table].filter(Sequel.~(:notes => nil)).each_by_page do |row|
        ASUtils.json_parse(row[:notes]).each do |note|
          values = {
            :notes => blobify(self, ASUtils.to_json(note)),
            :publish => note['publish'] ? 1 : 0,
            :notes_json_schema_version => row[:notes_json_schema_version],
            fk_column => row[:id]
          }

          [:created_by, :last_modified_by, :create_time, :system_mtime, :user_mtime].each do |col|
            if row.has_key?(col)
              values[col] = row[col]
            end
          end

          self[:note].insert(values)

          $stderr.puts("Migrated #{migrated_count} #{table} records") if (migrated_count % 1000) == 0
          migrated_count += 1
        end
      end
    end


    TABLES_WITH_NOTES.each do |table|
      alter_table(table) do
        drop_column :notes_json_schema_version
        drop_column :notes
      end
    end

  end


  down do
  end

end
