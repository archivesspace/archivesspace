class AgentSubreport < AbstractSubreport

	register_subreport('linked_agent', ['accession', 'archival_object',
		'digital_object', 'digital_object_component', 'event', 'resource',
		'rights_statement'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
		  linked_agents_rlshp.role_id as role,
		  linked_agents_rlshp.relator_id as relator,
		  linked_agents_rlshp.title as record_title,
		  group_concat(term.term separator '; ') as term,
		  concat_ws('; ',
		    group_concat(distinct name_person.primary_name separator '; '),
		    group_concat(distinct name_software.software_name separator '; '),
		    group_concat(distinct name_family.family_name separator '; '),
		    group_concat(distinct name_corporate_entity.primary_name separator '; ')
          ) as ref

		from linked_agents_rlshp

		  left outer join linked_agent_term
		    on linked_agent_term.linked_agents_rlshp_id
		    = linked_agents_rlshp.id
		    
		  left outer join term on term.id = linked_agent_term.term_id
		  
		  left outer join agent_person on agent_person.id
		    = linked_agents_rlshp.agent_person_id
		    
		  left outer join name_person on name_person.agent_person_id
			= agent_person.id
		    
		  left outer join agent_software on agent_software.id
		    = linked_agents_rlshp.agent_software_id
		    
		  left outer join name_software on name_software.agent_software_id
			= agent_software.id
		    
		  left outer join agent_family on agent_family.id
		    = linked_agents_rlshp.agent_family_id
		    
		  left outer join name_family on name_family.agent_family_id
			= agent_family.id

		  left outer join agent_corporate_entity on agent_corporate_entity.id
		    = linked_agents_rlshp.agent_corporate_entity_id
		    
		  left outer join name_corporate_entity
			on name_corporate_entity.agent_corporate_entity_id
			= agent_corporate_entity.id
		  
		where #{@id_type}_id = #{db.literal(@id)}
		group by linked_agents_rlshp.id"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:role, :relator])
	end

	def self.field_name
		'linked_agent'
	end
end