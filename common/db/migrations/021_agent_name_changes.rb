require_relative 'utils'

Sequel.migration do

  up do
    AGENT_TYPES = [:person, :family, :software, :corporate_entity]

    AGENT_TYPES.each do |agent_type|
      alter_table("name_#{agent_type}".intern) do
        add_column(:authorized, Integer, :null => true, :default => nil)
      end
    end


    AGENT_TYPES.each do |agent_type|
      table = "name_#{agent_type}".intern
      foreign_key = "agent_#{agent_type}_id".intern

      last_agent_seen = nil

      self[table].order(foreign_key, :id).each_by_page do |row|
        if row[foreign_key] != last_agent_seen
          self[table].filter(:id => row[:id]).update(:authorized => 1)
        end

        last_agent_seen = row[foreign_key]
      end
    end


    AGENT_TYPES.each do |agent_type|
      alter_table("name_#{agent_type}".intern) do
        add_unique_constraint([:authorized, "agent_#{agent_type}_id".intern],
                              :name => "#{agent_type}_one_authorized")
      end
    end

  end


  down do
  end

end

