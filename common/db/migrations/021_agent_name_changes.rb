require 'securerandom'
require_relative 'utils'

Sequel.migration do

  up do
    AGENT_TYPES = [:person, :family, :software, :corporate_entity]

    AGENT_TYPES.each do |agent_type|
      alter_table("name_#{agent_type}".intern) do
        add_column(:authorized, Integer, :null => true, :default => nil)
        add_column(:is_display_name, Integer, :null => true, :default => nil)
      end
    end


    AGENT_TYPES.each do |agent_type|
      table = "name_#{agent_type}".intern
      foreign_key = "agent_#{agent_type}_id".intern

      last_agent_seen = nil

      self[table].order(foreign_key, :id).each_by_page do |row|
        if row[foreign_key] != last_agent_seen
          self[table].filter(:id => row[:id]).update(:authorized => 1,
                                                     :is_display_name => 1)
        end

        last_agent_seen = row[foreign_key]
      end
    end


    AGENT_TYPES.each do |agent_type|
      alter_table("name_#{agent_type}".intern) do
        add_unique_constraint([:authorized, "agent_#{agent_type}_id".intern],
                              :name => "#{agent_type}_one_authorized")
        add_unique_constraint([:is_display_name, "agent_#{agent_type}_id".intern],
                              :name => "#{agent_type}_one_display_name")
      end
    end


    create_table(:name_authority_id) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      Integer :name_person_id, :null => true
      Integer :name_family_id, :null => true
      Integer :name_software_id, :null => true
      Integer :name_corporate_entity_id, :null => true

      String :authority_id, :null => false, :unique => true

      apply_mtime_columns
    end


    alter_table(:name_authority_id) do
      add_foreign_key([:name_person_id], :name_person, :key => :id)
      add_foreign_key([:name_family_id], :name_family, :key => :id)
      add_foreign_key([:name_software_id], :name_software, :key => :id)
      add_foreign_key([:name_corporate_entity_id], :name_corporate_entity, :key => :id)
    end


    NAME_TABLES = [:name_person, :name_corporate_entity, :name_family, :name_software]

    NAME_TABLES.each do
      |name_type|

      self[name_type].each_by_page do |row|
        if row[:authority_id]
          authority_id = row[:authority_id]

          if !self[:name_authority_id].filter(:authority_id => authority_id).empty?
            $stderr.puts("WARNING: Authority ID #{authority_id} was not unique.")
            authority_id = "#{authority_id}_#{SecureRandom.hex}"
            $stderr.puts("WARNING: Rewritten to #{authority_id}.")
          end

          self[:name_authority_id].insert("#{name_type}_id".intern => row[:id],
                                         :authority_id => authority_id,
                                         :created_by => row[:created_by],
                                         :last_modified_by => row[:last_modified_by],
                                         :create_time => row[:create_time],
                                         :system_mtime => row[:system_mtime],
                                         :user_mtime => row[:user_mtime])
        end
      end
    end


    NAME_TABLES.each do |table|
      alter_table(table) do
        drop_column(:authority_id)
      end
    end
  end


  down do
  end

end

