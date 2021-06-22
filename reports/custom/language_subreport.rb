class LanguageSubreport < AbstractSubreport

	register_subreport('language', ['archival_object', 'resource', 'digital_object',
		'digital_object_component'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end


	def query_string
		"select 
			language_and_script.language_id as language,
			language_and_script.script_id as script
 		from lang_material, language_and_script
 		where lang_material.id = language_and_script.lang_material_id
		 and #{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:language, :script])
	end

	def self.field_name
		'language'
	end
end
