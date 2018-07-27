class AgentRelatedAgentSubreport < AbstractSubreport

	register_subreport('related_agent', ['agent'])

	def initialize(parent_custom_report, agent_id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = agent_id
	end

	def query_string
		"select
			concat_ws('; ', person0.sort_name,
			family0.sort_name,
			software0.sort_name,
			ce0.sort_name,
			person1.sort_name,
			family1.sort_name,
			software1.sort_name,
			ce1.sort_name) as _agents,
			jsonmodel_type as relationship_type,
			description
		from related_agents_rlshp
			
			left outer join
				(select * from name_person where is_display_name)
				as person0
				on person0.agent_person_id
				= agent_person_id_0
			left outer join
				(select * from name_family where is_display_name)
				as family0
				on family0.agent_family_id
				= agent_family_id_0
			left outer join
				(select * from name_software where is_display_name)
				as software0
				on software0.agent_software_id
				= agent_software_id_0
			left outer join
				(select * from name_corporate_entity where is_display_name)
				as ce0
				on ce0.agent_corporate_entity_id
				= agent_corporate_entity_id_0
				
			left outer join
				(select * from name_person where is_display_name)
				as person1
				on person1.agent_person_id
				= agent_person_id_1
			left outer join(select * from name_family where is_display_name)
				as family1
				on family1.agent_family_id
				= agent_family_id_1
			left outer join
				(select * from name_software where is_display_name)
				as software1
				on software1.agent_software_id
				= agent_software_id_1
			left outer join
				(select * from name_corporate_entity where is_display_name)
				as ce1
				on ce1.agent_corporate_entity_id
				= agent_corporate_entity_id_1

		where #{@id_type}_id_0 = #{db.literal(@id)}
			or #{@id_type}_id_1 = #{db.literal(@id)}"
	end
	
	def fix_row(row)
		row[:relationship_type] = I18n.t("#{row[:relationship_type]}._singular")
	end

	def self.field_name
		'related_agent'
	end
end