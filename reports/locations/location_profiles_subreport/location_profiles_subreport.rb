class LocationProfilesSubreport < AbstractSubreport

	register_subreport('location_profile', ['location'])

	def initialize(parent_report, location_id)
		super(parent_report)
		@location_id = location_id
	end

	def query_string
		"select
			name,
			dimension_units_id as dimension_units,
			height,
			width,
			depth
		from location_profile, location_profile_rlshp
		where location_profile_rlshp.location_id = #{db.literal(@location_id)}
			and location_profile_rlshp.location_profile_id
			= location_profile.id"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:dimension_units])
		ReportUtils.fix_decimal_format(row, [:height, :width, :depth])
	end

	def self.field_name
		'location_profile'
	end
end