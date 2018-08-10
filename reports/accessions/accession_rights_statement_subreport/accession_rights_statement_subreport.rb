class AccessionRightsStatementSubreport < AbstractSubreport

	def initialize(parent_report, accession_id)
		super(parent_report)
		@accession_id = accession_id
	end

	def query_string
		"select
		  rights_type_id as rights_type,
		  statute_citation,
		  jurisdiction_id as jurisdiction,
		  status_id as status,
		  start_date as begin_date,
		  end_date,
		  determination_date,
		  license_terms,
		  other_rights_basis_id as other_rights_basis
		from rights_statement
		where accession_id = #{db.literal(@accession_id)}"
	end

	def fix_row(row)
		enum_fields = [:rights_type, :jurisdiction, :status, :other_rights_basis]
		ReportUtils.get_enum_values(row, enum_fields)
	end

end