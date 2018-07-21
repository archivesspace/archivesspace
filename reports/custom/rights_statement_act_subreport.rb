class RightsStatementActSubreport < AbstractSubreport

	register_subreport('rights_statement_act', ['rights_statement'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)
		@id = id
	end

	def query
		db.fetch(query_string)
	end

	def query_string
		"select
			act_type_id as act_type,
			restriction_id as restriction,
			start_date,
			end_date
		from rights_statement_act
		where rights_statement_id = #{@id}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:act_type, :restriction])
	end

	def self.field_name
		'rights_statement_act'
	end
end