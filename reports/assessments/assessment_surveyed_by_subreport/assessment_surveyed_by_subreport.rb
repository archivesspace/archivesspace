class AssessmentSurveyedBySubreport < AbstractSubreport

	register_subreport('surveyed_by', ['assessment'],
    	:translation => 'assessment.surveyed_by')

	def initialize(parent_report, assessment_id)
		super(parent_report)
		@assessment_id = assessment_id
	end

	def query_string
		"select
			name_person.sort_name as _surveyed_by
		from surveyed_by_rlshp
			join agent_person on agent_person.id
				= surveyed_by_rlshp.agent_person_id
			join name_person on name_person.agent_person_id = agent_person.id
		where assessment_id = #{db.literal(@assessment_id)}
			and name_person.is_display_name"
	end

	def self.field_name
		'surveyed_by'
	end
end