require_relative 'utils'

Sequel.migration do

  up do
    [:agent_person, :agent_software, :agent_corporate_entity,
     :agent_family, :subject].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end

