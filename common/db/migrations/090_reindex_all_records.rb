require_relative 'utils'

Sequel.migration do

  up do
    now = Time.now
    self.transaction do
      # touch all record types to trigger a reindex
      # this is necessary because of the changes to the PUI indexer,
      # and a related changes to the indexer code
      [:accession, :archival_object, :container_profile, :resource, :top_container,
       :digital_object, :agent_corporate_entity, :agent_family, :agent_person, :agent_software,
       :classification, :deaccession, :location, :location_profile, :repository, :subject,
       :vocabulary].each do |table|
        self[table].update(:system_mtime => now)
      end
    end
  end


  down do
    # not going to happen, people
  end

end

