require 'db/migrations/utils'

Sequel.migration do

  up do

    if AppConfig[:plugins].include?("container_management") 
      $stderr.puts "*" * 100 
      $stderr.puts "*\t\t You have the container_managment set in your AppConfig[:plugins] setting. We will not run the db migrations related to incorporating it into the ArchivesSpace core." 
      $stderr.puts "*" * 100 
      break 
    end


    create_editable_enum("restriction_type",
                         [
                           "RestrictedSpecColl",
                           "RestrictedCurApprSpecColl",
                           "RestrictedFragileSpecColl",
                           "InProcessSpecColl",
                           "ColdStorageBrbl"
                         ])


    if self[:enumeration].filter(:name => "dimension_units").count == 0
      create_enum("dimension_units", ["inches", "feet", "yards", "millimeters", "centimeters", "meters"])
    end


    create_table(:top_container) do
      primary_key :id

      Integer :repo_id, :null => false

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :barcode
      Integer :legacy_restricted, :default => 0

      String :ils_holding_id, :null => true
      String :ils_item_id, :null => true
      DateTime :exported_to_ils, :null => true

      String :indicator, :null => false, :index => true

      apply_mtime_columns
    end

    alter_table(:top_container) do
      add_unique_constraint([:repo_id, :barcode], :name => "top_container_uniq_barcode")
    end


    create_table(:sub_container) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :instance_id

      DynamicEnum :type_2_id
      String :indicator_2

      DynamicEnum :type_3_id
      String :indicator_3

      apply_mtime_columns
    end

    alter_table(:sub_container) do
      add_foreign_key([:instance_id], :instance, :key => :id)
    end


    create_table(:top_container_housed_at_rlshp) do
      primary_key :id
      Integer :top_container_id
      Integer :location_id
      Integer :aspace_relationship_position

      Integer :suppressed, :null => false, :default => 0

      String :jsonmodel_type, :null => false, :default => 'container_location'

      String :status
      Date :start_date
      Date :end_date
      String :note

      apply_mtime_columns(false)
    end

    alter_table(:top_container_housed_at_rlshp) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:location_id], :location, :key => :id)
    end


    create_table(:top_container_link_rlshp) do
      primary_key :id
      Integer :top_container_id
      Integer :sub_container_id
      Integer :aspace_relationship_position

      Integer :suppressed, :null => false, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:top_container_link_rlshp) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:sub_container_id], :sub_container, :key => :id)
    end


    create_table(:container_profile) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false

      String :name                     # unique
      String :url, :null => true       # optional

      String :extent_dimension         # enum ('height', 'width', 'depth')
      DynamicEnum :dimension_units_id  # default 'inches'

      String :height                   # validates as float
      String :width                    # validates as float
      String :depth                    # validates as float

      apply_mtime_columns
    end

    alter_table(:container_profile) do
      add_unique_constraint(:name, :name => "container_profile_name_uniq")
    end


    create_table(:top_container_profile_rlshp) do
      primary_key :id

      Integer :top_container_id
      Integer :container_profile_id
      Integer :aspace_relationship_position

      Integer :suppressed, :null => false, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:top_container_profile_rlshp) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:container_profile_id], :container_profile, :key => :id)
    end


    create_table(:rights_restriction) do
      primary_key :id

      Integer :resource_id
      Integer :archival_object_id

      String :restriction_note_type

      Date :begin, :null => true
      Date :end, :null => true
    end


    alter_table(:rights_restriction) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end


    create_table(:rights_restriction_type) do
      primary_key :id

      Integer :rights_restriction_id, :null => false
      DynamicEnum :restriction_type_id, :null => false
    end

    alter_table(:rights_restriction_type) do
      add_foreign_key([:rights_restriction_id], :rights_restriction, :key => :id, :on_delete => :cascade)
    end


    # Finally, trigger a reindex for affected record types
    now = Time.now
    [:accession, :archival_object, :container_profile, :resource, :top_container].each do |table|
      self[table].update(:system_mtime => now)
    end

    # Thank you, goodnight!
  end

end
