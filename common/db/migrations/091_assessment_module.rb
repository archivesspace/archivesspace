Sequel.migration do

  up do
    create_table(:assessment) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      TextField :accession_report
      TextField :appraisal
      TextField :container_list
      String :catalog_record
      String :control_file

      # What are these?
      # Integer :is_finding_aid_ead, :default => 0, :null => false
      # Integer :is_finding_aid_paper, :default => 0, :null => false
      # Integer :is_finding_aid_word, :default => 0, :null => false
      # Integer :is_finding_aid_spreadsheet, :default => 0, :null => false

      Date :surveyed_date
      String :surveyed_duration
      TextField :surveyed_extent

      TextField :purpose
      TextField :scope
      Integer :is_material_sensitive, :default => 0, :null => false

      apply_mtime_columns
    end

    alter_table(:assessment) do
      add_foreign_key([:repo_id], :repository, :key => :id)
    end


    create_table(:assessment_rlshp) do
      primary_key :id

      Integer :assessment_id, :null => false

      Integer :accession_id
      Integer :resource_id
      Integer :archival_object_id
      Integer :digital_object_id

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:assessment_rlshp) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end


    create_table(:surveyed_by_rlshp) do
      primary_key :id

      Integer :assessment_id, :null => false
      Integer :agent_person_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:surveyed_by_rlshp) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end


    create_table(:assessment_material) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :assessment_id, :null => false

      DynamicEnum :material_type_id, :null => false
      TextField :material_note, :null => false
      TextField :special_format_note
      TextField :exhibition_value_note

      apply_mtime_columns
    end

    alter_table(:assessment_material) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
    end

    create_editable_enum("assessment_material_type",
                         ['architectural_materials',
                          'art_originals',
                          'artifacts',
                          'audio_materials',
                          'biological_specimens',
                          'botanical_specimens',
                          'computer_storage_units',
                          'film',
                          'glass',
                          'photographs',
                          'scrapbooks',
                          'technical_drawings_and_schematics',
                          'textiles',
                          'vellum_and_parchment',
                          'video_materials',
                          'other'])


    create_table(:assessment_conservation_issue) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :assessment_id, :null => false

      DynamicEnum :issue_type_id, :null => false
      TextField :issue_note, :null => false

      apply_mtime_columns
    end

    alter_table(:assessment_conservation_issue) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
    end

    create_editable_enum("assessment_conservation_issue_type",
                         ['potential_mold_or_mold_damage',
                          'recent_pest_damage',
                          'deteriorating_film_base',
                          'brittle_paper',
                          'metal_fasteners',
                          'newspaper',
                          'tape',
                          'heat_sensitive_paper'])
  end

  down do
  end

end
