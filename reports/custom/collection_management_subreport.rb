class CollectionManagementSubreport < AbstractSubreport

	register_subreport('collection_management', ['accession', 'resource',
		'digital_object'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			processing_hours_per_foot_estimate,
			processing_total_extent as extent_number,
			processing_total_extent_type_id as extent_type,
			processing_hours_total,
			processing_plan,
			processing_priority_id as processing_priority,
			processing_status_id as processing_status,
			processing_funding_source,
			processors,
			rights_determined
		from collection_management
		where #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.fix_decimal_format(row, [:processing_hours_per_foot_estimate,
			:processing_hours_total])
		ReportUtils.fix_boolean_fields(row, [:rights_determined])
		ReportUtils.get_enum_values(row, [:extent_type, :processing_priority,
			:processing_status])
		ReportUtils.fix_extent_format(row)
	end

	def self.field_name
		'collection_management'
	end
end