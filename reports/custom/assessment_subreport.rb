class AssessmentSubreport < AbstractSubreport

	BOOLEAN_FIELDS = [:accession_report, :appraisal, :container_list,
		:catalog_record, :control_file, :deed_of_gift, :finding_aid_ead,
		:finding_aid_online, :finding_aid_paper, :finding_aid_word,
		:finding_aid_spreadsheet, :related_eac_records, :review_required,
		:inactive, :sensitive_material].freeze

	register_subreport('assessment', ['accession', 'resource',
		'archival_object', 'digital_object'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			assessment.id,
			assessment.accession_report,
			assessment.appraisal,
			assessment.container_list,
			assessment.catalog_record,
			assessment.control_file,
			assessment.deed_of_gift,
			assessment.finding_aid_ead,
			assessment.finding_aid_online,
			assessment.finding_aid_paper,
			assessment.finding_aid_word,
			assessment.finding_aid_spreadsheet,
			assessment.related_eac_records,
			assessment.survey_begin,
			assessment.survey_end,
			assessment.surveyed_duration,
			assessment.surveyed_extent,
			assessment.review_required,
			assessment.inactive,
			assessment.sensitive_material,
			assessment.purpose,
			assessment.scope,
			assessment.general_assessment_note,
			assessment.exhibition_value_note,
			assessment.existing_description_notes,
			assessment.review_note,
			assessment.monetary_value,
			assessment.monetary_value_note,
			assessment.special_format_note,
			assessment.conservation_note
		from assessment_rlshp, assessment
		where assessment_rlshp.assessment_id = assessment.id
			and assessment_rlshp.#{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.fix_boolean_fields(row, BOOLEAN_FIELDS)
		ReportUtils.fix_decimal_format(row, [:monetary_value])
		row[:ratings] = AssessmentRatingSubreport.new(
			self, row[:id]).get_content
		row[:formats] = AssessmentMaterialTypesFormatsSubreport.new(
			self, row[:id]).get_content
		row[:conservation_issues] = AssessmentConservationIssuesSubreport
			.new(self, row[:id]).get_content
		row[:surveyed_by] = AssessmentSurveyedBySubreport.new(
			self, row[:id]).get_content
		row[:reviewer] = AssessmentReviewerSubreport.new(
			self, row[:id]).get_content
	end

	def self.field_name
		'assessment'
	end
end