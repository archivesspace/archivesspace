class EventSubreport < AbstractSubreport

	register_subreport('event', ['accession',
		'archival_object', 'resource', 'digital_object',
		'digital_object_component', 'agent'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			event.id as id,
			event.event_type_id as event_type,
	    event.outcome_id as outcome,
	    event.timestamp
		from event, event_link_rlshp
		where event.id = event_link_rlshp.event_id
			and #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:event_type, :outcome])
		row[:date] = DateSubreport.new(self, row[:id]).get_content
		row.delete(:id)
	end

	def record_type
		'event'
	end

	def self.field_name
		'event'
	end
end