require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Triggering a reindex...")
    tables = [
      :resource,
      :digital_object,
      :accession,
      :agent_person,
      :agent_software,
      :agent_family,
      :agent_corporate_entity,
      :subject,
      :location,
      :event,
      :top_container,
      :classification,
      :container_profile,
      :location_profile,
      :archival_object,
      :digital_object_component,
      :classification_term,
      :assessment
    ]
    tables.each do |table|
    	self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end
