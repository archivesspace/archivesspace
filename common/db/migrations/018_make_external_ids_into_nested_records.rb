require_relative 'utils'

Sequel.migration do

  up do
    create_table(:external_id) do
      primary_key :id
      String :external_id, :null => false
      String :source, :null => false

      Integer :subject_id, :null => true
      Integer :accession_id, :null => true
      Integer :archival_object_id, :null => true
      Integer :collection_management_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true
      Integer :event_id, :null => true
      Integer :location_id, :null => true
      Integer :resource_id, :null => true

      apply_mtime_columns
    end

    alter_table(:external_id) do
      add_foreign_key([:subject_id], :subject, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:collection_management_id], :collection_management, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
      add_foreign_key([:event_id], :event, :key => :id)
      add_foreign_key([:location_id], :location, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end

    records_supporting_external_ids = [:subject, :accession, :archival_object, :collection_management, :digital_object,
                                       :digital_object_component, :event, :location, :resource]

    records_supporting_external_ids.each do |record|
      $stderr.puts("Migrating external IDs for records of type #{record}")

      many_to_many_table = "#{record}_ext_id".intern

      # populate the id columns for existing external documents
      self[many_to_many_table].each_by_page do |row|
        foreign_key = "#{record}_id".intern
        self[:external_id].insert(foreign_key => row[foreign_key],
                                  :source => row[:source],
                                  :create_time => row.fetch(:create_time, Time.now),
                                  :system_mtime => row.fetch(:system_mtime, Time.now),
                                  :user_mtime => row.fetch(:user_mtime, Time.now),
                                  :external_id => row[:external_id])
      end
    end

    records_supporting_external_ids.each do |record|
      $stderr.puts("Removing old external ID table for type #{record}")

      many_to_many_table = "#{record}_ext_id".intern

      # drop the old many-to-many table
      drop_table(many_to_many_table)
    end

  end


  down do
  end

end

