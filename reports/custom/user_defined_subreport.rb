class UserDefinedSubreport < AbstractSubreport

	register_subreport('user_defined', ['accession', 'resource', 'digital_object'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			boolean_1,
		    boolean_2,
		    boolean_3,
		    integer_1,
		    integer_2,
		    integer_3,
		    real_1,
		    real_2,
		    real_3,
		    string_1,
		    string_2,
		    string_3,
		    string_4,
		    text_1,
		    text_2,
		    text_3,
		    text_4,
		    text_5,
		    date_1,
		    date_2,
		    date_3
		from user_defined
		where #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.fix_boolean_fields(row, [:boolean_1, :boolean_2, :boolean_3])
		ReportUtils.fix_decimal_format(row, [:real_1, :real_2, :real_3])
	end

	def self.field_name
		'user_defined'
	end
end