class ExternalDocumentSubreport < AbstractSubreport

	register_subreport('external_document', ['accession',
		'archival_object', 'resource', 'subject', 'digital_object',
		'digital_object_component', 'agent_person',
		'agent_family', 'agent_corporate_entity', 'agent_software',
		'event', 'rights_statement'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query
		db.fetch(query_string)
	end

	def query_string
		"select
			title as record_title,
			location,
			publish,
			identifier_type_id as identifier_type
		from external_document
		where #{@id_type}_id = #{@id}"
	end

	def fix_row(row)
		ReportUtils.fix_boolean_fields(row, [:publish])
		ReportUtils.get_enum_values(row, [:identifier_type])
	end

	def self.field_name
		'external_document'
	end
end