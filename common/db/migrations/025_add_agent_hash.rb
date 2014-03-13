require_relative 'utils'
require 'digest/sha1'
require 'securerandom'

def get_unique_note
  {
    'jsonmodel_type' => 'note_bioghist',
    'subnotes' => [{
                     'jsonmodel_type' => 'note_text',
                     'content' => "This note was auto-generated during a database migration in order to differentiate two identical agent records. Note ID: #{SecureRandom.uuid}",
                     }]
  }
end

def calculate_hash(db, table, row)

  foreign_key = :"#{table}_id"
  hash_fields = []

  db[:date].filter(foreign_key => row[:id]).each do |date|
    hash_fields << %w(date_type_id label_id certainty_id expression begin end era_id calendar_id).map {|field|
      date[field.intern] || ' '
    }.join('_')
  end

  db[:agent_contact].filter(foreign_key => row[:id]).each do |contact|
    hash_fields <<  %w(name salutation_id telephone address_1 address_2 address_3 city region country post_code telephone_ext fax email email_signature note).map {|field|
      contact[field.intern] || ' '
    }.join('_')
  end

  db[:external_document].filter(foreign_key => row[:id]).each do |doc|
    hash_fields <<  %w(title location).map {|field|
      doc[field.intern] || ' '
    }.join('_')
  end

  db[:note].filter(foreign_key => row[:id]).each do |note|
    note_json = JSON.parse(note[:notes])
    note_json.delete("publish")
    note_json.delete("persistent_id")
    hash_fields << note_json.to_json.to_s
  end

  name_table = :"#{table.to_s.sub(/agent/, 'name')}"

  name_fields = %w(dates qualifier source_id rules_id)
  name_fields += case name_table
                 when :name_person
                   %w(primary_name name_order.id prefix rest_of_name suffix fuller_form number)
                 when :name_family
                   %w(family_name prefix)
                 when :name_corporate_entity
                   %w(primary_name subordinate_name_1 subordinate_name_2 number)
                 when :name_software
                   %w(software_name version manufacturer)
                 end

  db[name_table].filter(foreign_key => row[:id]).each do |name|
    next if name[:authorized] == 0

    hash_fields << name_fields.map {|field|
      name[field.intern] || ' '
    }.join('_')
  end

  Digest::SHA1.hexdigest(hash_fields.sort.join('-'))
end

Sequel.migration do

  AGENT_TABLES = [:agent_person, :agent_corporate_entity, :agent_family, :agent_software]

  up do

    # add a column for id'ing unique agents
    AGENT_TABLES.each do |table|
      puts "Adding agent_hash for #{table}"

      add_column table, :agent_sha1, String

      used_hashes = []

      self[table].each_by_page do |row|
        digest = calculate_hash(self, table, row)
        foreign_key = :"#{table}_id"

        if used_hashes.include?(digest)
          puts "Non-unique agent found. Adding a note to #{table} : #{row[:id]} to avoid conflict"
          # add a note
          new_note = get_unique_note
          values = {
            :notes => blobify(self, ASUtils.to_json(new_note)),
            :publish => 0,
            :notes_json_schema_version => 1,
            foreign_key => row[:id]
          }

          [:created_by, :last_modified_by, :create_time, :system_mtime, :user_mtime].each do |col|
            if row.has_key?(col)
              values[col] = row[col]
            end
          end

          self[:note].insert(values)

          # recalculate
          digest = calculate_hash(self, table, row)
          if used_hashes.include?(digest)
            raise Sequel::UniqueConstraintViolation.new("Gave up trying to create unique hashes for existing agents")
          end
        end

        used_hashes << digest

        self[table].filter(:id => row[:id]).update(:agent_sha1 => digest)
      end

      alter_table(table) do
        add_unique_constraint(:agent_sha1, :name => "sha1_#{table}")
        set_column_allow_null(:agent_sha1, false)
      end

    end

  end

  down do

    AGENT_TABLES.each do |table|
      puts "Dropping agent_sha1 column from #{table}"
      drop_column table, :agent_sha1
    end
  end

end
