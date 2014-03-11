require_relative 'utils'
require 'digest/sha1'

Sequel.migration do

  AGENT_TABLES = [:agent_person, :agent_corporate_entity, :agent_family, :agent_software]

  up do

    # add a column for id'ing unique agents
    AGENT_TABLES.each do |table|
      add_column table, :agent_sha1, String

      puts "Adding agent_hash for #{table}"
      self[table].each do |row|
        foreign_key = :"#{table}_id"

        hash_fields = []

        self[:date].filter(foreign_key => row[:id]).each do |date|
          hash_fields << %w(date_type_id label_id certainty_id expression begin end era_id calendar_id).map {|field|
            date[field.intern] || ' '
          }.join('_')
        end

        self[:agent_contact].filter(foreign_key => row[:id]).each do |contact|
          hash_fields <<  %w(name salutation_id telephone address_1 address_2 address_3 city region country post_code telephone_ext fax email email_signature note).map {|field|
            contact[field.intern] || ' '
          }.join('_')
        end

        self[:external_document].filter(foreign_key => row[:id]).each do |doc|
          hash_fields <<  %w(title location).map {|field|
            doc[field.intern] || ' '
          }.join('_')
        end

        self[:note].filter(foreign_key => row[:id]).each do |note|
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

        self[name_table].filter(foreign_key => row[:id]).each do |name|
          hash_fields << name_fields.map {|field|
            name[field.intern] || ' '
          }.join('_')
        end

        digest = Digest::SHA1.hexdigest(hash_fields.sort.join('-'))

        self[table].filter(:id => row[:id]).update(:agent_sha1 => digest)
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
