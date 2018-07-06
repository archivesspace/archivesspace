require_relative 'custom_field'

module RegisterCustomFields

	include CustomField::Mixin

	# for testing

	# register_field('global', 'FAKE_BOOLEAN_FIELD', 'Boolean')
	# register_field('global', 'FAKE_DATE_FIELD', 'Date',
	# 	:sortable => true)
	# register_field('global', 'FAKE_ENUM_FIELD', 'Enum',
	# 	:sortable => true, :enum_name => 'language_iso639_2')
	# register_field('global', 'FAKE_USER_FIELD', 'User',
	# 	:sortable => true)
	# register_field('global', 'FAKE_STRING_FIELD', String,
	# 	:sortable => true)

	register_field('global', 'created_by', 'User', :sortable => true,
		:translation_scope => 'advanced_search.text')
	register_field('global', 'last_modified_by', 'User', :sortable => true,
		:translation_scope => 'advanced_search.text')
	register_field('global', 'create_time', 'Date', :sortable => true,
		:translation_scope => 'advanced_search.date')
	register_field('global', 'user_mtime', 'Date', :sortable => true,
		:translation_scope => 'advanced_search.date')

	register_field('accession', 'access_restrictions', 'Boolean')
	register_field('accession', 'access_restrictions_note', String)
	register_field('accession', 'accession_date', 'Date',
		:sortable => true)
	register_field('accession', 'acquisition_type', 'Enum',
		:sortable => true)
	register_field('accession', 'condition_description', String)
	register_field('accession', 'content_description', String)
	register_field('accession', 'disposition', String)
	register_field('accession', 'identifier', String, :sortable => true)
	register_field('accession', 'general_note', String)
	register_field('accession', 'inventory', String)
	register_field('accession', 'provenance', String)
	register_field('accession', 'publish', 'Boolean')
	register_field('accession', 'resource_type', 'Enum', :sortable => true)
	register_field('accession', 'restrictions_apply', 'Boolean')
	register_field('accession', 'retention_rule', String)
	register_field('accession', 'title', String, :sortable => true)
	register_field('accession', 'use_restrictions', 'Boolean')
	register_field('accession', 'use_restrictions_note', String)

	register_field('agent', 'type', 'AgentType', :sortable => true)
	register_field('agent', 'publish', 'Boolean')
	register_field('agent', 'name', 'String', :sortable => true)

	register_field('archival_object', 'component_id', String,
		:sortable => true)
	register_field('archival_object', 'language', 'Enum', :sortable => true,
		:enum_name => 'language_iso639_2')
	register_field('archival_object', 'level', 'Enum', :sortable => true,
		:enum_name => 'archival_record_level')
	register_field('archival_object', 'publish', 'Boolean')
	register_field('archival_object', 'ref_id', String, :sortable => true)
	register_field('archival_object', 'repository_processing_note', String)
	register_field('archival_object', 'restrictions_apply', 'Boolean')
	register_field('archival_object', 'title', String, :sortable => true)

	register_field('assessment', 'accession_report', 'Boolean')
	register_field('assessment', 'appraisal', 'Boolean')
	register_field('assessment', 'container_list', 'Boolean')
	register_field('assessment', 'catalog_record', 'Boolean')
	register_field('assessment', 'control_file', 'Boolean')
	register_field('assessment', 'finding_aid_ead', 'Boolean')
	register_field('assessment', 'finding_aid_paper', 'Boolean')
	register_field('assessment', 'finding_aid_word', 'Boolean')
	register_field('assessment', 'finding_aid_spreadsheet', 'Boolean')
	register_field('assessment', 'surveyed_duration', String,
		:sortable => true)
	register_field('assessment', 'surveyed_extent', String,
		:sortable => true)
	register_field('assessment', 'review_required', 'Boolean')
	register_field('assessment', 'purpose', String, :sortable => true)
	register_field('assessment', 'scope', String, :sortable => true)
	register_field('assessment', 'sensitive_material', 'Boolean')
	register_field('assessment', 'general_assessment_note', String)
	register_field('assessment', 'special_format_note', String)
	register_field('assessment', 'exhibition_value_note', String)
	register_field('assessment', 'deed_of_gift', 'Boolean')
	register_field('assessment', 'finding_aid_online', 'Boolean')
	register_field('assessment', 'related_eac_records', 'Boolean')
	register_field('assessment', 'existing_description_notes', String)
	register_field('assessment', 'survey_begin', 'Date', :sortable => true)
	register_field('assessment', 'survey_end', 'Date', :sortable => true)
	register_field('assessment', 'review_note', String)
	register_field('assessment', 'inactive', 'Boolean')
	register_field('assessment', 'monetary_value', 'Decimal',
		:sortable => true)
	register_field('assessment', 'monetary_value_note', String)
	register_field('assessment', 'conservation_note', String)

	register_field('classification', 'description', String)
	register_field('classification', 'identifier', String,
		:sortable => true)
	register_field('classification', 'title', String, :sortable => true)

	register_field('digital_object_component', 'component_id', String,
		:sortable => true)
	register_field('digital_object_component', 'label', String)
	register_field('digital_object_component', 'language', 'Enum',
		:enum_name => 'language_iso639_2', :sortable => true)
	register_field('digital_object_component', 'publish', 'Boolean')
	register_field('digital_object_component', 'title', String,
		:sortable => true)

	register_field('digital_object', 'digital_object_id', String,
		:sortable => true)
	register_field('digital_object', 'digital_object_type', 'Enum',
		:sortable => true)
	register_field('digital_object', 'language', 'Enum', :sortable => true,
		:enum_name => 'language_iso639_2')
	register_field('digital_object', 'level', 'Enum', :sortable => true)
	register_field('digital_object', 'publish', 'Boolean')
	register_field('digital_object', 'restrictions', 'Boolean')
	register_field('digital_object', 'title', String, :sortable => true)

	register_field('event', 'event_type', 'Enum', :sortable => true)
	register_field('event', 'outcome', 'Enum', :sortable => true)
	register_field('event', 'outcome_note', String)

	register_field('location', 'area', String, :sortable => true)
	register_field('location', 'barcode', String, :sortable => true)
	register_field('location', 'building', String, :sortable => true)
	register_field('location', 'classification', String,
		:sortable => true)
	register_field('location', 'coordinate_1_indicator', String,
		:sortable => true)
	register_field('location', 'coordinate_1_label', String,
		:sortable => true)
	register_field('location', 'coordinate_2_indicator', String,
		:sortable => true)
	register_field('location', 'coordinate_2_label', String,
		:sortable => true)
	register_field('location', 'coordinate_3_indicator', String,
		:sortable => true)
	register_field('location', 'coordinate_3_label', String,
		:sortable => true)
	register_field('location', 'floor', String,
		:sortable => true)
	register_field('location', 'room', String,
		:sortable => true)
	register_field('location', 'temporary', 'Enum', :sortable => true)

	register_field('resource', 'identifier', String, :sortable => true)
	register_field('resource', 'language', 'Enum', :sortable => true,
		:enum_name => 'language_iso639_2')
	register_field('resource', 'level', 'Enum', :sortable => true,
		:enum_name => 'archival_record_level')
	register_field('resource', 'publish', 'Boolean')
	register_field('resource', 'repository_processing_note', String)
	register_field('resource', 'resource_type', 'Enum')
	register_field('resource', 'restrictions', 'Boolean')
	register_field('resource', 'title', String, :sortable => true)
	register_field('resource', 'ead_id', String, :sortable => true)
	register_field('resource', 'ead_location', String, :sortable => true)
	register_field('resource', 'finding_aid_title', String,
		:sortable => true)
	register_field('resource', 'finding_aid_subtitle', String,
		:sortable => true)
	register_field('resource', 'finding_aid_date', String,
		:sortable => true)
	register_field('resource', 'finding_aid_author', String,
		:sortable => true)
	register_field('resource', 'finding_aid_description_rules', 'Enum',
		:sortable => true)
	register_field('resource', 'finding_aid_language', String,
		:sortable => true)
	register_field('resource', 'finding_aid_sponsor', String,
		:sortable => true)
	register_field('resource', 'finding_aid_edition_statement', String)
	register_field('resource', 'finding_aid_series_statement', String)
	register_field('resource', 'finding_aid_status', 'Enum',
		:sortable => true)
	register_field('resource', 'finding_aid_note', String,
		:sortable => true)
	register_field('resource', 'finding_aid_subtitle', String,
		:sortable => true)

	register_field('rights_statement', 'rights_type', 'Enum',
		:sortable => true)
	register_field('rights_statement', 'statute_citation', String,
		:sortable => true)
	register_field('rights_statement', 'jurisdiction', 'Enum',
		:sortable => true)
	register_field('rights_statement', 'status', 'Enum',
		:sortable => true, :enum_name => 'rights_statement_ip_status')
	register_field('rights_statement', 'start_date', 'Date',
		:sortable => true)
	register_field('rights_statement', 'end_date', 'Date',
		:sortable => true)
	register_field('rights_statement', 'determination_date', 'Date',
		:sortable => true)
	register_field('rights_statement', 'license_terms', String,
		:sortable => true)
	register_field('rights_statement', 'other_rights_basis', 'Enum',
		:sortable => true)

	register_field('subject', 'title', String, :sortable => true,
		:alias => 'terms')
	register_field('subject', 'authority_id', String, :sortable => true)
	register_field('subject', 'scope_note', String)
	register_field('subject', 'source', 'Enum', :sortable => true)
end
