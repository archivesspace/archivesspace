require_relative 'utils'

Sequel.migration do

  up do
    create_table(:assessment_attribute_note) do
      primary_key :id

      Integer :assessment_id, :null => false
      Integer :assessment_attribute_definition_id, :null => false
      TextField :note, :null => false
    end

    alter_table(:assessment_attribute_note) do
      add_foreign_key([:assessment_id], :assessment, :key => :id)
      add_foreign_key([:assessment_attribute_definition_id], :assessment_attribute_definition, :key => :id)
    end

    self.transaction do
      self[:assessment_attribute]
        .filter(Sequel.~(:note => nil))
        .each do |row_with_note|

        self[:assessment_attribute_note].insert(:assessment_id => row_with_note[:assessment_id],
                                                :assessment_attribute_definition_id => row_with_note[:assessment_attribute_definition_id],
                                                :note => row_with_note[:note])
      end
    end

    # No null values anymore!
    self[:assessment_attribute].filter(:value => nil).delete

    alter_table(:assessment_attribute) do
      drop_column(:note)
      set_column_not_null(:value)
    end
  end

  down do
  end

end

