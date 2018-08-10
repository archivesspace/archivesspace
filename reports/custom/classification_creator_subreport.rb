class ClassificationCreatorSubreport < AbstractSubreport

	register_subreport('creator', ['classification'],
		:translation => 'classification.creator')

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			concat_ws('; ',
				group_concat(distinct name_person.primary_name separator '; '),
				group_concat(distinct name_software.software_name separator '; '),
				group_concat(distinct name_family.family_name separator '; '),
				group_concat(distinct name_corporate_entity.primary_name separator '; ')
			) as _creator

		from #{@id_type}_creator_rlshp
			
			left outer join agent_person on agent_person.id
				= #{@id_type}_creator_rlshp.agent_person_id
				
			left outer join name_person on name_person.agent_person_id
			= agent_person.id
				
			left outer join agent_software on agent_software.id
				= #{@id_type}_creator_rlshp.agent_software_id
				
			left outer join name_software on name_software.agent_software_id
			= agent_software.id
				
			left outer join agent_family on agent_family.id
				= #{@id_type}_creator_rlshp.agent_family_id
				
			left outer join name_family on name_family.agent_family_id
			= agent_family.id

			left outer join agent_corporate_entity on agent_corporate_entity.id
				= #{@id_type}_creator_rlshp.agent_corporate_entity_id
				
			left outer join name_corporate_entity
			on name_corporate_entity.agent_corporate_entity_id
			= agent_corporate_entity.id
			
		where #{@id_type}_id = #{db.literal(@id)}
		group by #{@id_type}_creator_rlshp.id"
	end

	def self.field_name
		'creator'
	end
end