class ExtentSubreport < AbstractSubreport

	register_subreport('extent', ['accession', 'deaccession',
		'archival_object', 'resource', 'digital_object',
		'digital_object_component'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end


	def query_string
		"select
			portion_id as portion,
			number as extent_number,
			extent_type_id as extent_type,
			container_summary,
			physical_details,
			dimensions
		from extent
		where #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:portion, :extent_type])
		ReportUtils.fix_extent_format(row)
	end

	def self.field_name
		'extent'
	end
end