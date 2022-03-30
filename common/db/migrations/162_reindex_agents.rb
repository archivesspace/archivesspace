require_relative 'utils'

Sequel.migration do

  up do
    [:agent_corporate_entity, :agent_person, :agent_family, :agent_software].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end
