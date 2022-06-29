require_relative 'utils'
require 'nokogiri'
require 'json'

def create_language_record_from_language_id(record_type, dataset, language_id)
  dataset.each do |row|

    linked_record_id = self[record_type].filter(:id => row[:id]).get(:id)
    language_value = self[record_type].filter(:language_id => row[:language_id]).get(:language_id)

    language_record = self[:lang_material].insert(
                          :json_schema_version => row[:json_schema_version],
                          "#{record_type}_id" => linked_record_id,
                          :create_time => row[:create_time],
                          :system_mtime => row[:system_mtime],
                          :user_mtime => row[:user_mtime]
                        )

    self[:language_and_script].insert(
                          :json_schema_version => row[:json_schema_version],
                          :language_id => language_value,
                          :lang_material_id => language_record,
                          :create_time => row[:create_time],
                          :system_mtime => row[:system_mtime],
                          :user_mtime => row[:user_mtime]
                        )
  end
end

def migrate_langmaterial_notes
  # Find all langmaterial notes
  self[:note].each do |note_id|
    if note_id[:notes].lit.include?('langmaterial')

      [ :resource_id, :archival_object_id, :digital_object_id, :digital_object_component_id ].each do |obj|
        record_id = note_id[obj]

        unless record_id.nil?
          # Create new lang_material record for remaining notes
          language_record = self[:lang_material].insert(
              :json_schema_version => note_id[:notes_json_schema_version],
              "#{obj}" => record_id,
              :create_time => note_id[:create_time],
              :system_mtime => note_id[:system_mtime],
              :user_mtime => note_id[:user_mtime]
              )

          note = note_id[:notes]
          puts "\nParsing note: #{JSON.parse(note)['content']}"
          # Handle notes that can be further parsed due to inline markup
          if note.lit.include?('<language')

              # grab just the xml from content
            split = note.split(/.*"content":\["/)
            split = split[1].tr("\"]}", "")
            parsed = Nokogiri::XML::DocumentFragment.parse(split.to_s) rescue nil
            languages = parsed.xpath('.//language') rescue nil
            languages&.each do |language|
              lang = language.attr('langcode')
              if !lang.nil?
                enum = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)
                langcode = self[:enumeration_value].filter(:value => lang, :enumeration_id => enum ).get(:id)

                puts "Updating language of material for #{obj} #{record_id}: #{lang} (#{langcode})"
                parsed_language_record = self[:lang_material].insert(
                    :json_schema_version => 1,
                    "#{obj}" => record_id,
                    :create_time => Time.now,
                    :system_mtime => Time.now,
                    :user_mtime => Time.now
                  )
                language_and_script = self[:language_and_script].insert(
                    :json_schema_version => 1,
                    :language_id => langcode,
                    :lang_material_id => parsed_language_record,
                    :create_time => Time.now,
                    :system_mtime => Time.now,
                    :user_mtime => Time.now
                  )
              end

              script = language.attr('scriptcode') rescue nil
              if !script.nil?
                enum = self[:enumeration].filter(:name => 'script_iso15924').get(:id)
                scriptcode = self[:enumeration_value].filter(:value => script, :enumeration_id => enum ).get(:id)

                puts "Updating script code for #{obj} #{record_id}: #{script} (#{scriptcode})"
                self[:language_and_script].filter(:id => language_and_script).update(
                    :script_id => scriptcode,
                  )
              end
            end

              # Strip inline markup from remaining note and migrate note
            content = note.gsub(/(<language langcode=\\"[a-z]+\\" scriptcode=\\"[A-z]+\\">(.[^<>]*)<\/language>)|(<language langcode=\\"[a-z]+\\">(.[^<>]*)<\/language>)|(<language langcode=\\"[a-z]+\\"\/>)/, '\\2\\4')

            new_note = content.lit.gsub('note_singlepart', 'note_langmaterial')

            puts "Updating language of material note content for #{obj} #{record_id}"
            puts "ORIGINAL CONTENT: #{JSON.parse(note)['content']}"
            puts "NEW CONTENT: #{JSON.parse(new_note)['content']}"

              # Switch note from linking to resource to linking to the new language record
            self[:note].filter(:id => note_id[:id]).update(
              :lang_material_id => language_record,
              "#{obj}" => nil,
              :notes => new_note.to_sequel_blob
              )
          else
            new_note = note_id[:notes].lit.gsub('note_singlepart', 'note_langmaterial')

            # Switch note from linking to resource to linking to the new language record
            self[:note].filter(:id => note_id[:id]).update(
              :lang_material_id => language_record,
              "#{obj}" => nil,
              :notes => new_note.to_sequel_blob
              )
          end
        end
      end
    end
  end
end

Sequel.migration do
  up do

    create_table(:lang_material) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true

      apply_mtime_columns
    end

    alter_table(:lang_material) do
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

    create_table(:language_and_script) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :lang_material_id

      DynamicEnum :language_id, :null => true
      DynamicEnum :script_id, :null => true

      apply_mtime_columns
    end

    alter_table(:language_and_script) do
      add_foreign_key([:lang_material_id], :lang_material, :key => :id)
    end

    alter_table(:note) do
      add_column(:lang_material_id, Integer, :null => true)
      add_foreign_key([:lang_material_id], :lang_material, :key => :id)
    end

    create_enum('note_langmaterial_type', ['langmaterial'])

    [:resource, :archival_object, :digital_object, :digital_object_component].each do |record|
      # take all values from language_id and turn them into language sub-records
      language_enum = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)
      create_language_record_from_language_id(record, self[record].filter( Sequel.~(:language_id => nil)), self[:enumeration_value].filter( :enumeration_id => language_enum).get(:id))
      # Drop old language_id column
      alter_table(record) do
        drop_foreign_key(:language_id)
      end
    end

    migrate_langmaterial_notes

    # Drop old langmaterial note from note_singlepart_type enumerations list
    enum = self[:enumeration].filter(:name => 'note_singlepart_type').get(:id)
    langmaterial = self[:enumeration_value].where(:value => 'langmaterial', :enumeration_id => enum )
    langmaterial.delete

    # Drop old langmaterial note from note_digital_object_type enumerations list
    enum = self[:enumeration].filter(:name => 'note_digital_object_type').get(:id)
    langmaterial = self[:enumeration_value].where(:value => 'langmaterial', :enumeration_id => enum )
    langmaterial.delete

  end
end
