class NamesSubreport < AbstractSubreport

	attr_accessor :record_type

	register_subreport('agent_name', ['agent'], :translation => 'agent.names')

	def initialize(parent_report, id)
		super(parent_report)
		@id = id
		record_type_parts = parent_report.record_type.split('_')
		@agent_type = record_type_parts[1...record_type_parts.length].join('_')
		@record_type = "name_#{@agent_type}"
	end

	def query_string
		"select
			name_#{@agent_type}.id,
			sort_name,
			source_id as source,
			rules_id as rules,
			authority_id
		from name_#{@agent_type}
			left outer join name_authority_id
				on name_authority_id.name_#{@agent_type}_id
				= name_#{@agent_type}.id
		where agent_#{@agent_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:source, :rules])
		row[:use_dates] = DateSubreport.new(self, row[:id]).get_content
		row.delete(:id)
	end
	
	def self.field_name
		'agent_name'
	end
	
end