module AgentSubrecords
  def validate_agent_defined
    agents_defined = 0
    agents_defined += 1 unless self.agent_person_id.nil?
    agents_defined += 1 unless self.agent_family_id.nil?
    agents_defined += 1 unless self.agent_corporate_entity_id.nil?
    agents_defined += 1 unless self.agent_software_id.nil?

    unless agents_defined == 1
      errors.add(:base, 'Exactly one agent type must be defined.') 
    end
  end
end
