class RightsStatementSubreport < AbstractSubreport

	register_subreport('rights_statement', ['accession', 'archival_object',
		'resource', 'digital_object', 'digital_object_component'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			rights_type_id as rights_type,
			statute_citation,
			jurisdiction_id as jurisdiction,
			status_id as status,
			start_date,
			end_date,
			determination_date,
			license_terms,
			other_rights_basis_id as other_rights_basis
		from rights_statement
		where #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		enum_fields = [:rights_type, :jurisdiction, :status, :other_rights_basis]
		ReportUtils.get_enum_values(row, enum_fields)
	end

	def self.field_name
		'rights_statement'
	end
end