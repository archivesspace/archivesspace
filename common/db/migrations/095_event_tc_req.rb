require 'db/migrations/utils'

Sequel.migration do

  up do
    # add reference identifier field to event
    alter_table(:event) do
      add_column(:refid, String, unique: true)
    end

    # add top container foreign key to event relationships table
    alter_table(:event_link_rlshp) do
      add_column(:top_container_id, Integer)
      add_foreign_key([:top_container_id], :top_container, key: :id)
    end

    # add event request enum values
    enums = {
      "event_event_type" => ["request"],
      "event_outcome" => ["cancelled", "fulfilled", "pending"],
      "linked_agent_event_roles" => ["requester"],
      "linked_event_archival_record_roles" => ["context", "requested"],
    }

    enums.each do |enumeration_name, values|
      enumeration_id = self[:enumeration].filter(
        name: enumeration_name
      ).get(:id)
      unless enumeration_id
        puts "Skipping missing enumeration: #{enumeration_name}"
        next
      end

      values.each do |value|
        enumeration_value_id = self[:enumeration_value].filter(
          enumeration_id: enumeration_id, value: value
        ).get(:id)

        # only add the values if they don't already exist
        if enumeration_value_id
          puts "Skipping pre-existing enumeration value: #{value}"
          next
        end

        position = self[:enumeration_value].filter(
          enumeration_id: enumeration_id
        ).max(:position) + 1

        self[:enumeration_value].insert(
          enumeration_id: enumeration_id,
          value: value,
          position: position,
          readonly: 1,
          create_time: Time.now,
          system_mtime: Time.now,
          user_mtime: Time.now
        )
      end
    end
  end

end
