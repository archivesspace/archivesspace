class AssessmentReviewerSubreport < AbstractSubreport

	register_subreport('reviewer', ['assessment'],
    	:translation => 'assessment.reviewer')

	def initialize(parent_report, assessment_id)
		super(parent_report)
		@assessment_id = assessment_id
	end

	def query_string
		"select
			name_person.sort_name as _reviewer
		from assessment_reviewer_rlshp
			join agent_person on agent_person.id
			= assessment_reviewer_rlshp.agent_person_id
			join name_person on name_person.agent_person_id = agent_person.id
		where assessment_id = #{db.literal(@assessment_id)}
			and name_person.is_display_name"
	end

	def self.field_name
		'reviewer'
	end
end