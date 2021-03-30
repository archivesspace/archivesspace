# Convenience methods for agent tests

# creates an agent via API call to the backend
# returns created agent ID, or -1 if error
def create_agent_via_api(agent_type, opts = {})
  case agent_type
  when :person
    agent_json = if opts[:create_subrecords]
                   build(:json_agent_person_full_subrec)
                 else
                   build(:json_agent_person)
                 end
    url = URI("#{JSONModel::HTTP.backend_url}/agents/people")
  when :corporate_entity
    agent_json = if opts[:create_subrecords]
                   build(:json_agent_corporate_entity_full_subrec)
                 else
                   build(:json_agent_corporate_entity)
                 end
    url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities")
  when :family
    agent_json = if opts[:create_subrecords]
                   build(:json_agent_family_full_subrec)
                 else
                   build(:json_agent_familly)
                 end
    url = URI("#{JSONModel::HTTP.backend_url}/agents/families")
  when :software
    agent_json = if opts[:create_subrecords]
                   build(:json_agent_software_full_subrec)
                 else
                   build(:json_agent_software)
                 end
    url = URI("#{JSONModel::HTTP.backend_url}/agents/software")
  end

  response = JSONModel::HTTP.post_json(url, agent_json.to_json)
  json_response = ASUtils.json_parse(response.body)

  if json_response['status'] == 'Created'
    json_response['id']
  else
    -1
  end
rescue StandardError => e
  -1
end

def add_gender_values
  ge = Enumeration.find(:name => 'gender')
  ge.add_enumeration_value(:value => 'female')
  ge.add_enumeration_value(:value => 'male')
  ge.add_enumeration_value(:value => 'non-binary')
end

def add_specific_relator_values
  spec_rel = Enumeration.find(:name => 'agent_relationship_specific_relator')
  spec_rel.add_enumeration_value(:value => 'daughterOf')
  spec_rel.add_enumeration_value(:value => 'correspondentOf')
  spec_rel.add_enumeration_value(:value => 'Acronym')
end
