# Convenience methods for agent tests

# creates an agent via API call to the backend
# returns created agent ID, or -1 if error
def create_agent_via_api(agent_type, opts = {})
	case agent_type
	when :person
		agent_json = opts[:create_subrecords] ? 
			build(:json_agent_person_full_subrec) : 
			build(:json_agent_person)
		url = URI("#{JSONModel::HTTP.backend_url}/agents/people")
	when :corporate_entity
	  agent_json = opts[:create_subrecords] ? 
			build(:json_agent_corporate_entity_full_subrec) : 
			build(:json_agent_corporate_entity)
		url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities")
	when :family
		agent_json = opts[:create_subrecords] ? 
			build(:json_agent_family_full_subrec) : 
			build(:json_agent_familly)
		url = URI("#{JSONModel::HTTP.backend_url}/agents/families")
	when :software
    agent_json = opts[:create_subrecords] ? 
			build(:json_agent_software_full_subrec) : 
			build(:json_agent_software)
		url = URI("#{JSONModel::HTTP.backend_url}/agents/software")
	end

  response = JSONModel::HTTP.post_json(url, agent_json.to_json)
  json_response = ASUtils.json_parse(response.body)

  if json_response["status"] == "Created"
    return json_response["id"]
  else
    return -1
	end
rescue => e
	return -1
end

def add_gender_values
	ge = Enumeration.find(:name => 'gender')
  ge.add_enumeration_value(:value => 'female')
  ge.add_enumeration_value(:value => 'male')
  ge.add_enumeration_value(:value => 'non-binary')
end