class ResourcesListReport < AbstractReport
	register_report
	
	def query_string
		"select
			id,
			title as record_title,
			identifier,
			level_id as level,
			resource_type_id as resource_type,
			language_id as language,
			publish,
			restrictions
		from resource
		where repo_id = #{db.literal(repo_id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:level, :resource_type, :language])
		ReportUtils.fix_boolean_fields(row, [:publish, :restrictions])
		ReportUtils.fix_identifier_format(row)
		row[:date] = ResourcesListDatesSubreport.new(self, row[:id]).get_content
		row[:extent] = ExtentSubreport.new(self, row[:id]).get_content
		row.delete(:id)
	end

	def record_type
		'resource'
	end

	def identifier_field
		:identifier
	end

	def special_translation(key, subreport_code)
		if subreport_code == 'extent_subreport'
			I18n.t("extent.#{key}", :default => nil)
		elsif subreport_code == 'date_subreport'
			I18n.t("date.#{key}", :default => nil)
		elsif !subreport_code
			I18n.t("resource.#{key}", :default => nil) unless key == 'title'
		end
	end
end