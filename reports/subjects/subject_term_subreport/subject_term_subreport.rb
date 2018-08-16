class SubjectTermSubreport < AbstractSubreport

	register_subreport('term', ['subject'])

	def initialize(parent_custom_report, subject_id)
		super(parent_custom_report)
		@subject_id = subject_id
	end

	def query_string
		"select
			term.term,
			term.term_type_id as term_type
		from subject_term, term
		where subject_term.term_id = term.id
			and subject_term.subject_id = #{db.literal(@subject_id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:term_type])
	end

	def self.field_name
		'term'
	end
end