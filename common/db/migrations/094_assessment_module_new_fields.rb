Sequel.migration do

  up do
    alter_table(:assessment) do
      add_column(:deed_of_gift, Integer, :null => true)
      add_column(:finding_aid_online, Integer, :null => true)
      add_column(:related_eac_records, Integer, :null => true)
      add_column(:documentation_notes, $db_type == :derby ? :clob : :text, :null => true)
      add_column(:survey_begin, Date, :null => false, :default => '1970-01-01')
      add_column(:survey_end, Date, :null => true)
      add_column(:review_note, $db_type == :derby ? :clob : :text, :null => true)
      add_column(:inactive, Integer, :null => true)
      add_column(:monetary_value, BigDecimal, :size => [16, 2], :null => true)
      add_column(:monetary_value_note, $db_type == :derby ? :clob : :text, :null => true)
    end

    self[:assessment].update(:survey_begin => :surveyed_date)

    alter_table(:assessment) do
      drop_column(:surveyed_date)
    end

    create_table(:assessment_reviewer_rlshp) do
      primary_key :id

      Integer :assessment_id, :null => false
      Integer :agent_person_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:assessment_reviewer_rlshp) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end
  end

  down do
  end

end
