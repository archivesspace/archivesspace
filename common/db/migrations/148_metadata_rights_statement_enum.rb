require_relative 'utils'


Sequel.migration do
  up do
    create_editable_enum('metadata_rights_statement', %w(public_domain non_commercial non_commercial_no_derivatives no_derivatives share_a_like non_commercial_share_a_like specific_terms copyright))
    create_table(:metadata_rights_declaration) do
      primary_key :id

      Integer :accession_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true
      Integer :subject_id, :null => true


      Integer :rights_statement_id, :null => true
      Integer :file_version_xlink_actuate_attribute_id, :null => true
      Integer :file_version_xlink_show_attribute_id, :null => true

      String :citation, :null => true
      TextField :descriptive_note, :null => false
      String :file_uri, :null => true
      String :xlink_title_attribute, :null => true
      String :xlink_role_attribute, :null => true
      String :xlink_arcrole_attribute, :null => true
      DateTime :last_verified_date, :null => true

      apply_mtime_columns
      Integer :lock_version, :default => 0, :null => false
    end

    alter_table(:metadata_rights_declaration) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
      add_foreign_key([:subject_id], :subject, :key => :id)
    end
  end
end
