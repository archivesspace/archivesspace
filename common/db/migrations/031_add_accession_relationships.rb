require_relative 'utils'

Sequel.migration do

  up do
    create_enum("accession_parts_relator", ["has_part", "forms_part_of"])
    create_editable_enum("accession_parts_relator_type", ["part"])

    create_enum("accession_sibling_relator", ["sibling_of"])
    create_editable_enum("accession_sibling_relator_type", ["bound_with"])

    create_table(:related_accession_rlshp) do
      primary_key :id

      Integer :accession_id_0
      Integer :accession_id_1

      Integer :suppressed, :null => false, :default => 0

      DynamicEnum :relator_id, :null => false
      DynamicEnum :relator_type_id, :null => false
      String :relationship_target_record_type, :null => false
      Integer :relationship_target_id, :null => false
      String :jsonmodel_type, :null => false

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end


    alter_table(:related_accession_rlshp) do
      add_foreign_key([:accession_id_0], :accession, :key => :id)
      add_foreign_key([:accession_id_1], :accession, :key => :id)
    end
  end
end
