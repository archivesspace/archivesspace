class LocationFunctionsSubreport < AbstractSubreport

	register_subreport('location_function', ['location'])

	def initialize(parent_report, location_id)
		super(parent_report)
		@location_id = location_id
	end

	def query_string
		"select
			location_function_type_id as _function_type
		from location_function
		where location_id = #{db.literal(@location_id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:_function_type])
	end

	def self.field_name
		'location_function'
	end
end