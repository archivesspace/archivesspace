require 'time'

Sequel.migration do

  # The 1.5.0 release introduced a bug that caused the "fullrecord" field to be
  # incomplete, causing certain subrecords (such as notes, extents and rights
  # statements) to be unsearchable.
  #
  # This migration triggers a reindex of affected record types.
  #
  up do
    reindex_types = [:top_container, :container_profile, :location_profile,
                     :archival_object, :resource, :digital_object,
                     :digital_object_component, :subject, :location,
                     :classification, :classification_term, :accession,
                     :agent_person, :agent_software, :agent_family,
                     :agent_corporate_entity]

    reindex_types.each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end

  down do
  end

end

