# patch up data left in a state where agent relationships have no agent
# see https://archivesspace.atlassian.net/browse/AR-1320

Sequel.migration do

  up do

    aspace_agent_id = self[:agent_software].filter( :system_role => 'archivesspace_agent' ).get(:id)

    self[:linked_agents_rlshp].filter(:agent_person_id => nil, :agent_software_id => nil, :agent_family_id => nil, :agent_corporate_entity_id => nil).update(:agent_software_id => aspace_agent_id)

  end


  down do

  end

end
