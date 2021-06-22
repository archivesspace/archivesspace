require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Migrating agent dates from 'date' to 'structured_date' table")

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

      if fits_structured_date_format?(r[:begin])
        std_begin = r[:begin]
      else
        std_begin = nil
      end

      if fits_structured_date_format?(r[:end])
        std_end = r[:end]
      else
        std_end = nil
      end

      # create date for expression date expression only
      if r[:expression]
        create_structured_date_for_expr(r, rel)
      end

      # if either a begin or end is defined at this point, then create either a single or ranged date
      if std_begin || std_end
        create_structured_dates(r, std_begin, std_end, rel)
      end

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
