require 'db/migrations/utils'

Sequel.migration do
	up do
    create_enum("sluggable_entity_type", 
    						["repository", 
    						 "agent_corporate_entity", 
    						 "agent_family", 
    						 "agent_person", 
    						 "agent_software", 
    						 "subject", 
    						 "resource", 
    						 "digital_object", 
    						 "accession", 
    						 "classification"]) 
	end
end
