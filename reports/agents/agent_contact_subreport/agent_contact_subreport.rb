class AgentContactSubreport < AbstractSubreport

	register_subreport('agent_contact', ['agent'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			id,
			name,
			salutation_id as salutation,
			address_1,
			address_2,
			address_3,
			city,
			region,
			country,
			post_code,
			email,
			email_signature,
			note
		from agent_contact
		where #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:salutation])
		row[:telephone] = AgentContactTelephoneSubreport.new(
			self, row[:id]).get_content
		row.delete(:id)
	end

	def self.field_name
		'agent_contact'
	end
end