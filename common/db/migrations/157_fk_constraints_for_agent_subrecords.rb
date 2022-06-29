require_relative 'utils'

Sequel.migration do
  up do
    # delete agent subrecord / subject relationships where the subject has been deleted
    [:subject_agent_subrecord_rlshp, :subject_agent_subrecord_place_rlshp].each do |table|
      deletes = []
      self[table].each do |row|
        subject_id = row[:subject_id]
        deletes << row[:id] if self[:subject].filter(:id => subject_id).count == 0
      end
      self[table].filter(:id => deletes).delete
    end

    alter_table(:subject_agent_subrecord_rlshp) do
      add_foreign_key([:subject_id], :subject, key: :id)
      add_foreign_key([:agent_function_id], :agent_function, key: :id)
      add_foreign_key([:agent_occupation_id], :agent_occupation, key: :id)
      add_foreign_key([:agent_place_id], :agent_place, key: :id)
      add_foreign_key([:agent_topic_id], :agent_topic, key: :id)
    end

    alter_table(:subject_agent_subrecord_place_rlshp) do
      add_foreign_key([:subject_id], :subject, key: :id)
      add_foreign_key([:agent_function_id], :agent_function, key: :id)
      add_foreign_key([:agent_occupation_id], :agent_occupation, key: :id)
      add_foreign_key([:agent_topic_id], :agent_topic, key: :id)
    end

    [:agent_record_control,
     :agent_alternate_set,
     :agent_conventions_declaration,
     :agent_other_agency_codes,
     :agent_maintenance_history,
     :agent_maintenance_history,
     :agent_sources,
     :structured_date_label,
     :agent_place,
     :agent_occupation,
     :agent_function,
     :agent_topic,
     :agent_gender,
     :agent_identifier,
     :used_language,
     :agent_resource,
    ].each do |table|
      alter_table(table) do
        add_foreign_key([:agent_person_id], :agent_person, :key => :id)
        next if table == :agent_gender
        add_foreign_key([:agent_family_id], :agent_family, :key => :id)
        add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
        add_foreign_key([:agent_software_id], :agent_software, :key => :id)
      end
    end

    alter_table(:parallel_name_person) do
      add_foreign_key([:name_person_id], :name_person, :key => :id)
    end

    alter_table(:parallel_name_family) do
      add_foreign_key([:name_family_id], :name_family, :key => :id)
    end

    alter_table(:parallel_name_corporate_entity) do
      add_foreign_key([:name_corporate_entity_id], :name_corporate_entity, :key => :id)
    end

    alter_table(:parallel_name_software) do
      add_foreign_key([:name_software_id], :name_software, :key => :id)
    end
  end
end
