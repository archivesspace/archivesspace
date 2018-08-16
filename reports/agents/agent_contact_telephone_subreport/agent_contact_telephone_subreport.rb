class AgentContactTelephoneSubreport < AbstractSubreport

	register_subreport('telephone', [])

	def initialize(parent, contact_id)
		super(parent)
		@contact_id = contact_id
	end

	def query_string
		"select
			number,
		    ext,
		    number_type_id as number_type
		from telephone
		where agent_contact_id = #{db.literal(@contact_id)}"
	end
	
	def fix_row(row)
		ReportUtils.get_enum_values(row, [:number_type])
	end

	def self.field_name
		'telephone'
	end
end