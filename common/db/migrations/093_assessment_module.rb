Sequel.migration do

  up do
    create_table(:assessment) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      TextField :display_string, :null => true

      Integer :accession_report, :default => 0, :null => false
      Integer :appraisal, :default => 0, :null => false
      Integer :container_list, :default => 0, :null => false
      Integer :catalog_record, :default => 0, :null => false
      Integer :control_file, :default => 0, :null => false
      Integer :finding_aid_ead, :default => 0, :null => false
      Integer :finding_aid_paper, :default => 0, :null => false
      Integer :finding_aid_word, :default => 0, :null => false
      Integer :finding_aid_spreadsheet, :default => 0, :null => false

      Date :surveyed_date
      String :surveyed_duration
      TextField :surveyed_extent
      Integer :review_required, :default => 0, :null => false

      TextField :purpose
      TextField :scope
      Integer :sensitive_material, :default => 0, :null => false

      TextField :general_assessment_note

      TextField :special_format_note
      TextField :exhibition_value_note

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


    create_table(:assessment_attribute_definition) do
      primary_key :id
      Integer :repo_id, :null => false
      String :label, :null => false
      String :type, :null => false
      Integer :position, :null => false
    end

    alter_table(:assessment_attribute_definition) do
      add_unique_constraint([:repo_id, :type, :label], :name => "assessment_attr_unique_label")
    end

    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Reformatting Readiness', :type => 'rating', :position => 0)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Housing Quality', :type => 'rating', :position => 1)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Physical Condition', :type => 'rating', :position => 2)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Physical Access (arrangement)', :type => 'rating', :position => 3)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Intellectual Access (description)', :type => 'rating', :position => 4)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Interest', :type => 'rating', :position => 5)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Documentation Quality', :type => 'rating', :position => 6)

    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Architectural Materials', :type => 'format', :position => 7)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Art Originals', :type => 'format', :position => 8)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Artifacts', :type => 'format', :position => 9)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Audio Materials', :type => 'format', :position => 10)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Biological Specimens', :type => 'format', :position => 11)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Botanical Specimens', :type => 'format', :position => 12)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Computer Storage Units', :type => 'format', :position => 13)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Film (negative, slide, or motion picture)', :type => 'format', :position => 14)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Glass', :type => 'format', :position => 15)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Photographs', :type => 'format', :position => 16)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Scrapbooks', :type => 'format', :position => 17)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Technical Drawings & Schematics', :type => 'format', :position => 18)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Textiles', :type => 'format', :position => 19)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Vellum & Parchment', :type => 'format', :position => 20)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Video Materials', :type => 'format', :position => 21)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Other', :type => 'format', :position => 22)

    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Potential Mold or Mold Damage', :type => 'conservation_issue', :position => 23)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Recent Pest Damage', :type => 'conservation_issue', :position => 24)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Deteriorating Film Base', :type => 'conservation_issue', :position => 25)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Brittle Paper', :type => 'conservation_issue', :position => 26)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Metal Fasteners', :type => 'conservation_issue', :position => 27)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Newspaper', :type => 'conservation_issue', :position => 28)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Tape', :type => 'conservation_issue', :position => 29)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Heat-Sensitive Paper', :type => 'conservation_issue', :position => 30)
    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Water Damage', :type => 'conservation_issue', :position => 31)

    create_table(:assessment_attribute) do
      primary_key :id

      Integer :assessment_id, :null => false
      Integer :assessment_attribute_definition_id, :null => false
      String :value, :null => true
    end

    alter_table(:assessment_attribute) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
      add_foreign_key([:assessment_attribute_definition_id], :assessment_attribute_definition, :key => :id)
    end


    # create_table(:assessment_material) do
    #   primary_key :id
    # 
    #   Integer :lock_version, :default => 0, :null => false
    #   Integer :json_schema_version, :null => false
    # 
    #   Integer :assessment_id, :null => false
    # 
    #   DynamicEnum :material_type_id, :null => false
    #   TextField :material_note, :null => false
    #   TextField :special_format_note
    #   TextField :exhibition_value_note
    # 
    #   apply_mtime_columns
    # end
    # 
    # alter_table(:assessment_material) do
    #   add_foreign_key([:assessment_id], :assessment, :key => :id)
    # end
    # 
    # create_editable_enum("assessment_material_type",
    #                      ['architectural_materials',
    #                       'art_originals',
    #                       'artifacts',
    #                       'audio_materials',
    #                       'biological_specimens',
    #                       'botanical_specimens',
    #                       'computer_storage_units',
    #                       'film',
    #                       'glass',
    #                       'photographs',
    #                       'scrapbooks',
    #                       'technical_drawings_and_schematics',
    #                       'textiles',
    #                       'vellum_and_parchment',
    #                       'video_materials',
    #                       'other'])
    # 
    # 
    # create_table(:assessment_conservation_issue) do
    #   primary_key :id
    # 
    #   Integer :lock_version, :default => 0, :null => false
    #   Integer :json_schema_version, :null => false
    # 
    #   Integer :assessment_id, :null => false
    # 
    #   DynamicEnum :issue_type_id, :null => false
    #   TextField :issue_note, :null => false
    # 
    #   apply_mtime_columns
    # end
    # 
    # alter_table(:assessment_conservation_issue) do
    #   add_foreign_key([:assessment_id], :assessment, :key => :id)
    # end
    # 
    # create_editable_enum("assessment_conservation_issue_type",
    #                      ['potential_mold_or_mold_damage',
    #                       'recent_pest_damage',
    #                       'deteriorating_film_base',
    #                       'brittle_paper',
    #                       'metal_fasteners',
    #                       'newspaper',
    #                       'tape',
    #                       'heat_sensitive_paper'])


    # TODO bootstrap update_assessment_record permission to those worthy 
  end

  down do
  end

end
