require_relative 'utils'

Sequel.migration do

  up do
    now = Time.now
    [:assessment, :agent_person, :agent_family, :agent_corporate_entity, :agent_software].each do |table|
      self[table].update(:system_mtime => now)
    end
  end


  down do
  end

end

