class DeaccessionSubreport < AbstractSubreport

	register_subreport('deaccession', ['accession', 'resource'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			scope_id as scope,
			description,
			reason,
			disposition,
			notification
		from deaccession
		where #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:scope])
		ReportUtils.fix_boolean_fields(row, [:notification])
	end

	def self.field_name
		'deaccession'
	end
end