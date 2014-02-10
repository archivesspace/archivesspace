require_relative 'utils'

Sequel.migration do

  up do
    [:resource, :archival_object, :digital_object, :digital_object_component, :accession,
     :event, :agent_person, :agent_family, :agent_corporate_entity, :agent_software].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end

