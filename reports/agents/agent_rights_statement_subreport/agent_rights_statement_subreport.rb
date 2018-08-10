class AgentRightsStatementSubreport < AbstractSubreport

	register_subreport('rights_statement', ['agent'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			rights_statement.id,
			rights_type_id as rights_type,
			statute_citation,
			jurisdiction_id as jurisdiction,
			status_id as status,
			start_date,
			end_date,
			determination_date,
			license_terms,
			other_rights_basis_id as other_rights_basis
		from linked_agents_rlshp, rights_statement
		where linked_agents_rlshp.rights_statement_id
			= rights_statement.id
			and linked_agents_rlshp.#{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		enum_fields = [:rights_type, :jurisdiction, :status, :other_rights_basis]
		ReportUtils.get_enum_values(row, enum_fields)
		row[:accession] = LinkedAccessionSubreport.new(self, row[:id]).get_content
		row[:archival_object] = LinkedArchivalObjectSubreport.new(
			self, row[:id]).get_content
		row[:digital_object] = LinkedDigitalObjectSubreport.new(
			self, row[:id]).get_content
		row[:digital_object_component] = LinkedDigitalObjectComponentSubreport.new(
			self, row[:id]).get_content
		row[:resource] = LinkedResourceSubreport.new(self, row[:id]).get_content
		row.delete(:id)
	end

	def record_type
		'rights_statement'
	end

	def self.field_name
		'rights_statement'
	end
end