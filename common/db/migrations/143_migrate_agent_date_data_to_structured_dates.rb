require_relative 'utils'

def create_structured_date(r, rel)
  type_id = (r[:date_type_id] == DATE_TYPE_SINGLE_ID_ORIG ? TYPE_ID_SINGLE : TYPE_ID_RANGE)

  l = self[:structured_date_label].insert(:date_label_id => r[:label_id],
                                          :date_type_structured_id => type_id,
                                          :date_certainty_id => r[:certainty_id],
                                          :date_era_id => r[:era_id],
                                          :date_calendar_id => r[:calendar_id],
                                          :create_time => Time.now,
                                          :system_mtime => Time.now,
                                          :user_mtime => Time.now,
                                          rel => r[rel])

  # create ranged date if end date present
  if type_id == TYPE_ID_RANGE

    self[:structured_date_range].insert(:begin_date_standardized => r[:begin],
                                        :end_date_standardized => r[:end],
                                        :begin_date_expression => r[:expression],
                                        :structured_date_label_id => l,
                                        :create_time => Time.now,
                                        :system_mtime => Time.now,
                                        :user_mtime => Time.now)

  # otherwise, create a single, begin date if we have a begin
  else
    self[:structured_date_single].insert(:date_role_id => ROLE_ID_BEGIN,
                                         :date_standardized => r[:begin],
                                         :date_expression => r[:expression],
                                         :structured_date_label_id => l,
                                         :create_time => Time.now,
                                         :system_mtime => Time.now,
                                         :user_mtime => Time.now)
  end
end

Sequel.migration do
  up do
    $stderr.puts("Migrating agent dates from 'date' to 'structured_date' table")

    DATE_TYPE_SINGLE_ID_ORIG = get_enum_value_id("date_type", "single")
    DATE_TYPE_RANGE_ID_ORIG = get_enum_value_id("date_type", "range")
    DATE_TYPE_BULK_ID_ORIG = get_enum_value_id("date_type", "bulk")
    DATE_TYPE_INCLUSIVE_ID_ORIG = get_enum_value_id("date_type", "inclusive")

    ROLE_ID_BEGIN = get_enum_value_id("date_role", "begin")
    ROLE_ID_END = get_enum_value_id("date_role", "end")
    TYPE_ID_SINGLE = get_enum_value_id("date_type_structured", "single")
    TYPE_ID_RANGE = get_enum_value_id("date_type_structured", "range")

    # figure out which FK is defined, so we can create the right relationship later
    self[:date].order(:id).paged_each do |r|
      if r[:agent_person_id]
        rel = :agent_person_id
      elsif r[:agent_family_id]
        rel = :agent_family_id
      elsif r[:agent_corporate_entity_id]
        rel = :agent_corporate_entity_id
      elsif r[:agent_software_id]
        rel = :agent_software_id
      elsif r[:name_person_id]
        rel = :name_person_id
      elsif r[:name_family_id]
        rel = :name_family_id
      elsif r[:name_corporate_entity_id]
        rel = :name_corporate_entity_id
      elsif r[:name_software_id]
        rel = :name_software_id
      elsif r[:related_agents_rlshp_id]
        rel = :related_agents_rlshp_id
      else
        next
      end

      log_date_migration(r)
      create_structured_date(r, rel)

      self[:date].filter(:id => r[:id]).delete
    end # of loop

    # remove agents related FKs from date table
    alter_table(:date) do
      drop_foreign_key(:agent_person_id)
      drop_foreign_key(:agent_family_id)
      drop_foreign_key(:agent_corporate_entity_id)
      drop_foreign_key(:agent_software_id)
      drop_foreign_key(:name_person_id)
      drop_foreign_key(:name_family_id)
      drop_foreign_key(:name_corporate_entity_id)
      drop_foreign_key(:name_software_id)
      drop_foreign_key(:related_agents_rlshp_id)
    end
  end # of up
end # of migration
